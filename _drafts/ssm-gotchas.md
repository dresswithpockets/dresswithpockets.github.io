---
layout: post
title:  "AWS SSM Kind of Sucks (but thats okay)"
date:   2023-09-01 10:45:00 -0700
tags:   aws ssm sre
---

These are some of my discoveries while helping a company move from SSH to AWS SSM.

## Be Prepared

Warning! This post assumes you have some basic understanding of how to use SSM and what SSM [Sessions](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html), [Commands](https://docs.aws.amazon.com/systems-manager/latest/userguide/run-command.html), and [Documents](https://docs.aws.amazon.com/systems-manager/latest/userguide/documents.html) are.

If you are new to SSM, then I recommend doing the following to get acquainted with it before reading this article:
1. Read [General SSM setup](https://docs.aws.amazon.com/systems-manager/latest/userguide/setting_up_prerequisites.html)
1. Read [Setting up SSM for EC2](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-setting-up-ec2.html)
1. Spin up an ec2 instance, with IMDSv2 support
1. [Install SSM Agent](https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-manual-agent-install.html) 3.2.582 or later on that instance
    - this is necessary for [DHCP](https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-permissions.html#default-host-management).
1. [Install Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) for your AWS cli locally
1. [Start a session](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html) to your ec2 instance
1. Read up on [Sessions](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html), [Commands](https://docs.aws.amazon.com/systems-manager/latest/userguide/run-command.html), and [Documents](https://docs.aws.amazon.com/systems-manager/latest/userguide/documents.html).

## Background

We have a fleet of thousands of servers. SSH keys for every engineer are distributed to these servers based on the access they should have. We also have some scripts that remotely execute many SSH commands across many instances.

Outside of SSH, we manage permissions to AWS resources via AWS IAM. We generally follow least-privilege practices, and use tags to automate access. All of our engineers' IAM users are federated through an AWS IdP like Okta.

These two authentication mechanisms are disparate, and often at odds with eachother. A user may not have privileges for some team's resources through IAM, but their SSH key might be configured to propogate to those resources. This possibility alone is problematic.

### ABAC-based IAM

In our case, every federated user has access to roles with a `team` tag. The `team` tag is a single string value indicating the team that the role belongs to. When authenticated into that role, the user will generally have access to every AWS resource that team owns. The `team` tag is associated with the role as a Principal Tag.

## Stop Using SSH

SSH is difficult to administer at scale, especially in infrastructures that already have other systems of providing IAM for access to resources. Instances shouldnt be generally accessible to the internet. So, you usually have to maintain additional infrastructure to facilitate SSH'ing into instances, such as internet-facing bastions or a VPN.

SSM Sessions are proxied through the AWS SSM service. No more port 22; no more internet-facing bastions; no more VPN-just-for-ssh.

If you already use SSH, with bastions in your infra, I recommend the following after fully switching over to SSM:
1. Configure a "recovery" SSH key
  - ideally, this key is rotated regularly, and after every use
1. Configure a "recovery" bastion ASG (or your favourite auto-scaling service), and keep it at 0 scale
  - ideally, this would only ever be scaled in in response to the rare SSM outage
1. Scale in all other bastions

## Make Your Own Tooling

If you already have an internal CLI tool or a pool of internal scripts, I highly recommend adding common SSM operations to it. Virtually every operation I describe below is made simpler by tooling we maintain.

## Account Wide SSM Settings

AWS automatically creates a document `SSM-SessionManagerRunShell` in every account. Allowing `ssm:StartSession` also implicitly grants access to this document.

> Important! This document is implicitly invoked whenever a session is started via `aws ssm start-session`, but not when invoking `ssm:StartSession`.

You can manage that document in IaC tools like terraform, but you'll likely need to import it into your managed state.

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

## Can't Always Use Tags For Permissions

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

### Problem: Sessions and Commands cant be tagged

As a result, there isn't a tag-based approach to permissioning that applies to `ssm:ResumeSession`, `ssm:TerminateSession`, `ssm:*CommandInvocation`, `ssm:CancelCommand`.

You might notice that Sessions you create have an ID with a format along the lines of `{username}-abcd1234`. We can take advantage of this, since `ResumeSession` and `TerminateSession` provide `aws:resourceTag/aws:ssmmessages:session-id` as a condition key. AWS [recommends](https://docs.aws.amazon.com/systems-manager/latest/userguide/getting-started-restrict-access-examples.html#restrict-access-example-instance-tags) a policy like this:

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

Unfourtunately, federated users [do not get a userid](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_variables.html#policy-vars-infotouse). I recommend giving [_How to integrate AWS STS SourceIdentity with your identity provider_](https://aws.amazon.com/blogs/security/how-to-integrate-aws-sts-sourceidentity-with-your-identity-provider/) a read.

For Okta-federated users, the username used in the session ID is likely the email or username the user uses to log into Okta. Following the instructions in the aforementioned article, you should be able to map the user's Okta Email to the AWS Username.

As of Sept 1st, 2023, we havent implemented this approach yet. I expect it to look something like:

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

WIP

## Port Tunneling over SSM sucks (but only a little bit)

WIP

## SCP over SSM also sucks

WIP

## Stop Using AWS-Managed Documents

You've probably setup permissions along these lines for AWS documents:

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

`AWS-StartPortForwardingSession`'s `portNumber` parameter takes an arbitrary port. This is akin to federating access to a VPN, and then exposing every port on the instance to the VPN. No good.

Instead, lets create our own documents with a specific list of allowed ports.

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