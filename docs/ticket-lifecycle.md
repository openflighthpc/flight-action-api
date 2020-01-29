# Ticket (and Job) Creation Life Cycle

This document primary purposes is to describe the creation cycle of `tickets`/`jobs` and will cover the following concepts:
* `tickets`
* `jobs`
* `commands`
* `scripts`/`pool`
* `ranks`
* `variables`/`variable dictionary`

These concepts are independent but otherwise related to the resources of the same names. Not all of these concepts have corresponding resources.

This document is intended for system administrators and integrators. API consumers should look through the [routes documentation](routes.md) instead. The following describes in detail what happens when a "ticket resource" is created.

*NOTE*: The goal is to provide documentation on how `tickets`/`jobs` are processed, however the run order of individual events has not been preserved. In practice, once a list of `jobs` has been generated, each `job` is processed sequentially.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://tools.ietf.org/html/rfc2119).

## Step 1: Process the request inputs and build the ticket model

The first step stage is processing the request for the related `context` and `command`. The `command` is looked up via the `CommandFacade` ([refer to README for details](../README.md)] by its `id` which also doubles as its `name`. This SHOULD assign the `command` to the `ticket` or SHALL be a missing association.

The `context` SHOULD be either a `group` or `node` resource identifier object and will be looked up by ID via the `GroupFacade` or `NodeFacade` respectively. The relationship SHALL be a missing association if the lookup fails to find a `context` or if a different api type was provided.

If either the `context` or `command` is missing, then a empty `jobs` set SHALL be assigned to the `ticket`. 
This makes the following operation fairly trivial and will not be discussed in detail.

The `jobs` set SHALL be compiled according to the following protocol:
1. If the `command` or `context` is missing, then `jobs` forms an empty set,
2. Else If the context is a `group`, then a `job` is generated for each `node` within the `group`,
3. Else a single element `jobs` set is generated for the `node` given by the `context`.

Each `job` relates directly to the `ticket` and there transiently related to its `command`.

## Step 2: Select the scripts for each node by rank

Next a `script` must be selected for the `job`. This is done by comparing the `job`'s `node` against its `command`.
*NOTE*: `jobs` are transiently related to a `command` via it's `ticket`.

By design a `command` can have multiple `scripts` classified by `rank`. This is so a different `script` can be ran on a per node basis for the same `command`.

All `commands` MUST have a default ranked script (`default script`) but MAY have many other ranks of scripts. The set of available ranked scripts for a particular `command` is known as a `pool`. Each `node` MAY have a list of `ranks`. The `pool` is compared against the `node`'s `ranks` to select the `script` for the `job`.

* If the `node` has (remaining) `ranks`:
    1. The first(/next) `rank` from `ranks` is compared against the `pool` for the `command`
    2. Repeat from the beginning with the next `rank` if no `script` is found
    3. Selects the `script` from the `pool` with matching `rank`
* Otherwise:
  * Select the `default script`

This process of matching a `node` against a `command` is guaranteed to find a `script` even if it's the `default script`. The `default script` can be either used as a fallback or to disable a `command` on a per `node` basis.

## Step 3: Generate the variable dictionary for the job

Before a `job` can be ran, it needs to be given access to its "variables". Each `script` MAY have an associated list of `variables` which form the "keys" to the `job`'s `variable dictionary`. The `variable dictionary` SHALL be empty for a `scipt` without `variables`.

The "values" to the `variable dictionary` are generated from the `node` "parameters". These "parameters" form the full set of possible "variables". The values of the `variables` in the `variable dictionary` SHALL be either the values contained within the parameters or empty string.

## Step 4: Setup and run the jobs
*README: Injection Attack Risk!*

Each `job` is ran in a dedicated `bash` shell which then executes the `script` body. The `variable dictionary` is directly set into the shell's environment and thus is available to the `script` using regular bash variables. The working directory of the bash shell is set in the main [application config](../config/application.yaml).

These "variables are the raw parameters returned from the `NodeFacade`; no form of output sanitization has been performed. It is the responsibility of the system administrator/ integrator to ensure the `NodeFacade` is configured with a trusted source.

There is no mechanism to feed inputs from the API consumer into the script execution and therefore mitigates the threat of an injection attack from this source.

## Step 5: "Log", Serialize and issue the response

Through out `ticket` creation life cycle, the results of the above steps would have been logged. Refer to [application config](../config/application.yaml]) for the log location.

The `ticket` as well as the `jobs`, `command`, `context`, and associated `nodes` are then serialized and issued as the response to the client. This entire process is synchronous.

