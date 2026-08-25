# qb-core (compat wrapper)

A wrapper resource whose only job is to **occupy the resource name `qb-core`**
so that legacy scripts' `@qb-core/...` file includes resolve.

It contains no framework logic. The real implementation is
[qbcore2/qbcore](https://github.com/qbcore2/qbcore); this resource forwards to
it.

## The problem it solves

Real qb-core-era scripts (qb-doorlock, qb-banking, qb-recyclejob, …) declare:

```lua
shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
}
```

FiveM has three separate mechanisms that all look like "resource identity", and
they do **not** cover each other:

| Mechanism | What satisfies it |
|---|---|
| `dependency 'qb-core'` | a real resource named `qb-core`, **or** any started resource with `provide 'qb-core'` |
| `exports['qb-core']:Fn()` | whichever resource registers the `__cfx_export_qb-core_Fn` event (the identity hijack qbcore's `compat/*` uses) |
| `shared_script '@qb-core/bar.lua'` | **only** a real, started resource literally named `qb-core`, with `bar.lua` in its `files {}` block |

`qbcore` already carries `provide 'qb-core'` and the export identity hijack, so
the first two rows are covered. The third is not: an `@name/path` include is
resolved by the *file loader*, which never consults `provide` or the export
registry.

Because a failed include is not a fatal error, the consumer starts anyway with
a missing global, and it surfaces later as a confusing error deep inside that
consumer's own code:

```
[c-scripting-core] Failed to load script @qb-core/shared/locale.lua.
[   script:qb-banking] SCRIPT ERROR: @qb-banking/locales/en.lua:33: attempt to index a nil value (global 'Locale')
```

## How it works

`shared/locale.lua` forwards to the canonical implementation rather than
duplicating it:

```lua
local chunk = LoadResourceFile('qbcore', 'shared/locale.lua')
local fn = assert(load(chunk, '@qbcore/shared/locale.lua'))
fn()
```

The forward — rather than a `shared_script '@qbcore/...'` in this resource's own
manifest — is the load-bearing detail: the consumer's include runs this file **in
the consumer's VM**, so the `Locale` global it defines lands where the consumer
can see it. A `shared_script` in this manifest would instead run it in *this*
resource's VM, where nothing needs it.

## Install

Place in `resources/[compat]/` and ensure it **after** `qbcore` (its
`LoadResourceFile` target must already exist) and **before** any legacy consumer:

```cfg
ensure qbcore
ensure qb-core
ensure qb-banking
```

Do not run a real qb-core alongside this.
