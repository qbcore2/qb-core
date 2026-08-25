-- Forwarder. A consumer's `shared_script '@qb-core/shared/locale.lua'` lands
-- here; we immediately hand off to qbcore's real implementation, which builds
-- the `Locale` global (and the `Lang` instance its own locales/*.lua files
-- expect) in that consumer's VM. Keeping this a pure forward means there is one
-- implementation to maintain (qbcore/shared/locale.lua), not two.
--
-- We cannot `shared_script '@qbcore/shared/locale.lua'` from HERE -- that would
-- run it in this wrapper's VM, not the consumer's. Instead the consumer that
-- included us gets qbcore's file loaded into ITS VM via the load below.
-- Identical technique to qbsql/stubs/oxmysql/lib/MySQL.lua.
local chunk = LoadResourceFile('qbcore', 'shared/locale.lua')
assert(chunk, '[qb-core-wrapper] could not read qbcore/shared/locale.lua -- is qbcore present?')
local fn = assert(load(chunk, '@qbcore/shared/locale.lua'))
fn()
