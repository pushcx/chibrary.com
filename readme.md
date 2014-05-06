Chibrary
========

TODO what it does

Install instructions
* Install Riak 1.4.8
* Install Redis 2.4.15
* Run `bundle install` to install the gems

Influences:
  Sandi Metz: Practical Object-Oriented Design in Ruby, Magic Tricks of Testing
  J.B. Rainsberger: Integration Tests Are A Scam
  Gary Bernhardt: Boundaries; Functional Core, Imperative Shell
  Eric Evans: Domain Driven Design

TODO

From the bottom up:

== Values

Values are immutable objects without identity or state, They are small,
reliable data structures. These should all prepend the DeepFreeze module.
If any wanted to use attr_accessor, it would not be a Value.

A few are persisted. They are never updated, though they may be discarded and
replaced. Arguably this makes them an Entity, but they have no code and I
don't want them built in a mutable way.

Entities
Repo
Services
Web

Tests
  duplication

  contract
  collaboration
  integration
