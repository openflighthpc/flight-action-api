# Ticket (and Job) Creation Life Cycle
# STALE: NEEDS UPDATING

This document primary purposes is to describe the creation cycle of `tickets`/`jobs` and will cover the following concepts:
* `tickets`
* `jobs`
* `commands`
* `scripts`/`pool`
* `ranks`
* `variables`

These concepts are independent but otherwise related to the resources of the same names. Not all of these concepts have corresponding resources.

The order of the following sections form the logical sequence of events, but additional batching and job scheduling may occur.

This document is intended for system administrators and integrators. API consumers should look through the [routes documentation](routes.md) instead. The following describes in detail what happens when a "ticket resource" is created.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://tools.ietf.org/html/rfc2119).

## Resolving the Context and Command

### tl;dr 

Make sure each request is assigned to a `command` and either a `group` or `node`.
Everything should work as expected ...

### Detailed

All requests SHOULD have a related `context` and `command` resources identifiers. These identifiers are looked up against the applications "data backend" (mode specific) and MAY resolve to models. The `context` resource identifier SHOULD be of types `nodes` or `groups`. The `command` MUST be of type `commands`.

If the `context` is not of types `nodes` or `groups` it SHALL be considered missing. The following conditions apply to both the `context` and `command` equally. The resource SHALL be considered missing if the identifier is:
* omitted from the request, or
* could not be resolved into a model from it's `type`

The `ticket` SHALL be assigned an empty set of jobs if either the `context` or `command` is missing. This is a fairly trivial request which will bypass most of the following stages.

The `jobs` set SHALL be compiled according to the following protocol:
1. If the `command` or `context` is missing, then `jobs` forms an empty set,
2. Else If the context is a `group`, then a `job` is generated for each `node` within the `group`,
3. Else a single element `jobs` set is generated for the `node` given by the `context`.

## Using Ranks to Assign a Script to a Job

There are two options on how to proceed here

### tl;dr

Each `command` MUST have a `default script` which will be ran unless otherwise configured.
Feel free to move on ...

### Detailed

Sometimes it is useful to have multiple `scripts` for the same `command`. This allows each `node` to run a slightly different version of the `command`. The ranking mechanism is responsible for matching a `script` to a `node`. Broadly the `command` has many `scripts` catagorised by `rank` and the `node` defines the priority order for those `ranks`.

All `commands` MUST have a default ranked script (`default script`) but MAY have many other ranks of scripts. The set of available ranked scripts for a particular `command` is known as a `pool`. Each `node` MAY have a list of `ranks`. The `pool` is compared against the `ranks` to select the `script`.

* If the `node` has (remaining) `ranks`:
  1. The first(/next) `rank` from `ranks` is compared against the `pool`
  2. Repeat from the beginning with the next `rank` if no `script` is found
  3. Selects the `script` from the `pool` with the matching `rank`
* Otherwise:
  * Select the `default script`

This process of matching a `node` against a `command` is guaranteed to find a `script` as it can use the `default script` as a fallback. This allows `default script` to either define a generic version or "disable" it with an error on a per `node` basis.

## Setting Shell Variables and Executing the Job

### tl;dr

You should probably read this ...

### Detailed
*README: Injection Attack Risk!*

As an alternative to using `ranks` to customising the `script`, shell variables MAY be set into the environment. All the jobs SHALL be spawned using `/bin/sh` which MAY be symlinked to `/bin/bash` depending on distribution.

The term `variables` refer to following two related concepts:
* an array of "keys" which are stored against the `script`, and
* they "key-value" pairs that form shell variables.

Each `node` has a `parameters` dictionary which is used to convert the `variables` from an array to "key-value" pairs. The value SHALL come from `parameters` when the key exists in the dictionary. The value SHALL be empty string when the key does not exist in `parameters`.

The working directory of the process is also set as per the [application configuration](../config/application.yaml.reference).

Care MUST be taken when working with `variables` as they form an injection attack vector. It is the joint responsibility of the developers, system administrators, and integrators to mitigate this risk. The following design considerations have been made:
* It is not possible pass client inputs as `variable`, and
* The `variables` are directly set into the environment and thus bypass string interpolation.

*NOTE FOR SYSTEM ADMINISTRATORS AND INTEGRATORS*
It is your responsibility to ensure the `variables` come from a trusted source. No form of input sanitization has been preformed.

## Final Notes

Through out `ticket` creation life cycle, the results of the above steps would have been logged. Refer to [application config](../config/application.yaml]) for the log location.

The `ticket` as well as the `jobs`, `command`, `context`, and associated `nodes` are then serialized and issued as the response to the client. This entire process is synchronous.

