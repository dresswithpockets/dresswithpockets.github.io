---
layout: post
title:  "AWS SSM Kind of Sucks (and that's okay)"
date:   2023-09-02 10:45:00 -0700
tags:   aws ssm sre
---

These are some of my discoveries while helping a company move from SSH to AWS SSM.

1. [Be Prepared](#be-prepared)
1. [Background](#background)
    1. [ABAC-Based IAM](#abac-based-iam)
1. [Stop Using SSH](#stop-using-ssh)
1. [Make Your Own Tooling](#make-your-own-tooling)
1. [Account Wide SSM Settings](#account-wide-ssm-settings)
1. [Use Tags For Permissions](#use-tags-for-permissions)
    1. [Problem: Sessions and Commands can't be tagged](#problem-sessions-and-commands-cant-be-tagged)
    1. [Problem: Federated users don't get a userid](#problem-federated-users-dont-get-a-userid)
1. [SSH over SSM kind of sucks](#ssh-over-ssm-kind-of-sucks)
1. [Port Tunneling over SSM kind of sucks](#port-tunneling-over-ssm-kind-of-sucks)
1. [SCP over SSM also sucks](#scp-over-ssm-also-sucks)
1. [Stop Using AWS-Managed Documents](#stop-using-aws-managed-documents)

## Be Prepared

**Warning!** This post assumes you have some basic understanding of how to use SSM and what SSM [Sessions](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html), [Commands](https://docs.aws.amazon.com/systems-manager/latest/userguide/run-command.html), and [Documents](https://docs.aws.amazon.com/systems-manager/latest/userguide/documents.html) are.

If you are new to SSM, then I recommend doing the following to get acquainted with it before reading this post:
1. Follow [General SSM setup](https://docs.aws.amazon.com/systems-manager/latest/userguide/setting_up_prerequisites.html)
1. Follow [Setting up SSM for EC2](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-setting-up-ec2.html)
1. Spin up an ec2 instance, with IMDSv2 support
1. [Install SSM Agent](https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-manual-agent-install.html) 3.2.582 or later on that instance
    - this is necessary for [DHMC](https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-permissions.html#default-host-management).
1. [Install Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) for your AWS CLI locally
1. [Start a session](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html) to your ec2 instance
1. Read up on [Sessions](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html), [Commands](https://docs.aws.amazon.com/systems-manager/latest/userguide/run-command.html), and [Documents](https://docs.aws.amazon.com/systems-manager/latest/userguide/documents.html).

## Background

We have a fleet of thousands of servers. SSH keys for every engineer are distributed to these servers based on the access they should have. We also have some scripts that remotely execute many SSH commands across many instances.

Outside of SSH, we manage permissions to AWS resources via AWS IAM. We generally follow least-privilege practices and use tags to automate access. Our engineers' IAM users are federated through an AWS IdP like Okta.

These two authentication mechanisms are disparate and often at odds with each other. Users may not have privileges for some team's resources through IAM, but their SSH key might be configured to propagate to those resources. This possibility alone is problematic.

### ABAC-based IAM

In our case, every federated user can access roles tagged with a `team` Principal Tag. The `team` tag is a single string value indicating the team the role belongs to. When authenticated into that role, the user will generally have access to every AWS resource that the team owns.

Taggable resources are tagged by the teams that own them and additional teams that can access them. Most of our IAM policies for user roles have Condition rules for these tags. You'll see an example of that later.

## Stop Using SSH

SSH is difficult to administer at scale, especially in infrastructures with other systems providing IAM for access to resources. Instances shouldn't be generally accessible to the internet. You usually must maintain additional infrastructure to facilitate SSH'ing into instances, such as internet-facing bastions or a VPN.

SSM Sessions are proxied through the AWS SSM service. No more port 22, no more internet-facing bastions, no more VPN-just-for-ssh.

If you already use SSH, with bastions in your infra, I recommend the following after fully switching over to SSM:
1. Configure a "recovery" SSH key
    - ideally, this key is rotated regularly and after every use
1. Configure a "recovery" bastion ASG (or your favourite auto-scaling service), and keep it at 0 scale
    - ideally, this would only ever be scaled in in response to the rare SSM outage
1. Scale in all other bastions

## Make Your Own Tooling

If you already have an internal CLI tool or a pool of internal scripts, I recommend adding common SSM operations.

As you'll see later, whenever you want to forward a port from a host, you have to write something like this:

```sh
aws ssm start-session \
  --target i-abcd1234 \
  --document AWS-StartPortForwardingSession \
  --parameters 'portNumber=8080,localPortNumber=8080'
```

It'd be nice to have an alias or CLI tool that's a bit more familiar, like:

```sh
start-session i-abcd1234 -L 8080:localhost:8080
```

Virtually every operation I describe below is made simpler by the tooling we maintain.

## Account Wide SSM Settings

AWS automatically creates a document `SSM-SessionManagerRunShell` in every account. Allowing `ssm:StartSession` also implicitly grants access to this document.

> Important! This document is implicitly invoked whenever a session is started via `aws ssm start-session`, but not when invoking `ssm:StartSession`.

You can manage that document in IaC tools like Terraform, but you'll likely need to import it into your managed state.

```sh
terraform import aws_ssm_document.ssm_session_manager_run_shell "SSM-SessionManagerRunShell"
```

```terraform
resource "aws_ssm_document" "ssm_settings" {
  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    /* copy SSM-SessionManagerRunShell's content from the Session Manager console */
  })
}
```

## Use Tags For Permissions

For `ssm:StartSession` and `ssm:SendCommand`, its trivial to filter permission by tag:

```terraform
data "aws_iam_policy_document" "allow_ssm_for_teams" {
  statement {
    effect  = "Allow"
    actions = [
      "ssm:StartSession",
      "ssm:SendCommand",
    ]
    resources = [ /* ec2 instance arns or arn pattern */ ]
    condition {
      test     = "StringLike"
      variable = "ssm:resourceTag/team"
      values   = [ "$${aws:PrincipalTag/team}" ]
    }
  }
}
```

With a policy like this, users can only `StartSession` or `SendCommand` with EC2 instances tagged with a matching team tag.

### Problem: Sessions and Commands can't be tagged

As a result, there isn't a tag-based approach to permissions that applies to `ssm:ResumeSession`, `ssm:TerminateSession`, `ssm:*CommandInvocation`, and `ssm:CancelCommand`.

You might notice that the Sessions you create have an ID with a format like `{username}-abcd1234`. We can take advantage of this, since `ResumeSession` and `TerminateSession` provide `aws:resourceTag/aws:ssmmessages:session-id` as a condition key. AWS [recommends](https://docs.aws.amazon.com/systems-manager/latest/userguide/getting-started-restrict-access-examples.html#restrict-access-example-instance-tags) a policy like this:

```terraform
data "aws_iam_policy_document" "allow_ssm_sessions_for_users" {
  statement {
    effect  = "Allow"
    actions = [
      "ssm:ResumeSession",
      "ssm:TerminateSession",
    ]
    resources = [ "arn:aws:ssm:*:*:session/$${aws:userid}-*" ]
  }
}
```

### Problem: Federated users don't get a userid

Unfortunately, federated users [do not get a userid](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_variables.html#policy-vars-infotouse). I recommend giving [_How to integrate AWS STS SourceIdentity with your identity provider_](https://aws.amazon.com/blogs/security/how-to-integrate-aws-sts-sourceidentity-with-your-identity-provider/) a read.

For Okta-federated users, the username used in the session ID is likely the email or username the user uses to log into Okta. Following the instructions in the article mentioned above, you should be able to map the user's Okta Email to the AWS Username.

As of Sept 2nd, 2023, we still need to implement this approach. I expect it to look something like this:

```terraform
data "aws_iam_policy_document" "allow_ssm_sessions_for_users" {
  statement {
    effect  = "Allow"
    actions = [
      "ssm:ResumeSession",
      "ssm:TerminateSession",
    ]
    resources = [ "arn:aws:ssm:*:*:session/$${aws:PrincipalTag/login}-*" ]
  }
}
```

## SSH over SSM kind of sucks

Like us, you may have some tooling that depends on being able to ssh(1) to many hosts in a fleet. If that's the case, AWS supports using SSM as a proxy command for SSH. Say you want to be able to do something like:

```sh
ssh user@i-abcd1234
```

You can configure SSH with something like this:
```
Host i-*
  ProxyCommand sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
```

You still need to distribute SSH keys, so this is useful as a stop-gap while transitioning to entirely SSM-based fleet management.

## Port Tunneling over SSM kind of sucks

If you're used to doing something like `ssh host -L 8080:localhost:8080`, SSM can tunnel ports for you with Port sessions. AWS provides a few managed documents that are preconfigured to support this. For example:

```sh
aws ssm start-session \
  --target i-abcd1234 \
  --document AWS-StartPortForwardingSession \
  --parameters 'portNumber=8080,localPortNumber=8080'
```

You can also tunnel to a remote host via a jumpbox, the equivalent of `ssh host -L 8080:some_remote_host:8080`:

```sh
aws ssm start-session \
  --target i-abcd1234 \
  --document AWS-StartPortForwardingSessionToRemoteHost \
  --parameters 'host=some_host,portNumber=8080,localPortNumber=8080'
```

However, I urge you to read the contents of the managed documents you end up using; I go over an example of why you should care in [this section](#stop-using-aws-managed-documents).

## SCP over SSM also sucks

This section might be a bit unfulfilling - my information for SCP-over-SSM is lacking, since someone else implemented SSM-based file transfers.

If you've configured support for SSH-over-SSM, then scp(1) should "just work." **However**, I recommend relying on something other than this stop-gap configuration for file transfers, especially if you plan on eventually phasing out general SSH use.

There is no SSM-native way to transfer files between hosts. You must share files remotely via S3 or another service and then download them on the target machine.

Our tooling basically just does this:
1. Send command to remote instance, to upload files to a shared S3 bucket
1. Locally download the newly uploaded S3 objects

Or a variation of this for local-to-remote and remote-to-remote file transfers.

## Stop Using AWS-Managed Documents

You've probably set permissions along these lines for AWS documents:

```terraform
data "aws_iam_policy_document" "allow_ssm_documents" {
  statement {
    effect  = "Allow"
    actions = [ "ssm:StartSession" ]
    resources = [
      "arn:aws:ssm:*::document/AWS-StartPortForwardingSession",
      "arn:aws:ssm:*::document/AWS-StartSSHSession",
      "arn:aws:ssm:*::document/AWS-StartInteractiveCommand",
    ]
  }
  statement {
    effect  = "Allow"
    actions = [ "ssm:SendCommand" ]
    resources = [
      "arn:aws:ssm:*::document/AWS-RunShellScript",
      "arn:aws:ssm:*::document/AWS-StartInteractiveCommand",
    ]
  }
}
```

If we take a look at the contents of one of those documents, something seems a bit fishy:

```jsonc
/* AWS-StartPortForwardingSession content */
{
  /* ... */
  "parameters": {
    "portNumber": {
      "type": "String",
      "description": "(Optional) Port number of the server on the instance",
      "allowedPattern": "^([1-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$",
      "default": "80"
    },
    /* ... */
  },
  /* ... */
}
```

`AWS-StartPortForwardingSession`'s `portNumber` parameter takes an arbitrary port. This is akin to federating access to a VPN and then exposing every port on the instance to the VPN. No good.

Instead, create your own documents with a specific list of allowed ports.

```terraform
locals {
  allowed_ports      = [ 8080, 8081, 8082 ]
  host_port_pattern  = "^(${join("|", local.allowed_ports)})$"
  /* using the same port pattern from the managed document, but only for local-machine ports */
  local_port_pattern = "^([0-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$"
}

resource "aws_ssm_document" "start_port_forwarding_session" {
  name            = "DressesDigital-StartPortForwardingSession"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode ({
    schemaVersion = "1.0"
    description   = "Document to start port forwarding session over Session Manager"
    sessionType   = "Port"
    parameters    = {
      portNumber = {
        type           = "String"
        description    = "(Optional) Port number of the server on the instance",
        allowedPattern = local.host_port_pattern,
        default        = "8080"
      }
      localPortNumber = {
        type           = "String"
        description    = "(Optional) Port number on local machine to forward traffic to. An open port is chosen at run-time if not provided",
        allowedPattern = local.local_port_pattern,
        default        = "8080"
      }
    }
    properties = {
      type            = "LocalPortForwarding"
      portNumber      = "{{ portNumber }}"
      localPortNumber = "{{ localPortNumber }}"
    }
  })
}
```

This ruleset can be applied to the other port forwarding documents.