---
layout: default
title: Among The Stars
---

hi, i'm ashley. [they/she](https://en.pronouns.page/@dresswithpockets).

{% if site.posts.size > 0 %}
I've talked about some stuff:

<ul>
  {% for post in site.posts %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}</a>
    </li>
  {% endfor %}
</ul>
{% endif %}

I've worked on a few games:

- [The Pink Sea](https://steamcommunity.com/sharedfiles/filedetails/?id=3092347199)
- [Little Leaf](https://dressesdigital.itch.io/little-leaf), for the [2022 Cozy Autumn Jam](https://itch.io/jam/mini-jam-77-courage/rate/981963)
- [Stone Spire](https://dressesdigital.itch.io/stone-spire), for the [77th Mini Jam](https://itch.io/jam/mini-jam-77-courage/rate/981963)
- [TrashRPG](https://dressesdigital.itch.io/trashrpg), for the [A2B2 Charity Jam](https://itch.io/jam/a2b2-game-jam)
- [Project Borealis](https://projectborealis.com/)
- [Cart Ride Into Male_07](https://steamcommunity.com/sharedfiles/filedetails/?id=3613070733)

And, I've made a few things:

- [openstats](https://github.com/dresswithpockets/openstats) - personal game stats & achievment tracking
- [odin-godot](https://github.com/dresswithpockets/odin-godot) - a Godot toolkit for Odin
- [FakeS3](https://github.com/dresswithpockets/FakeS3) - in-memory and on-disk S3 provider for .NET
- [Scenario](https://github.com/dresswithpockets/Scenario) - tool for prescribing tests in C#
