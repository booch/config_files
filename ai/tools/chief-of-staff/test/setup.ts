// Journal headings and timestamps use local time; pin it so tests are deterministic.
process.env.TZ = "UTC";

// Test repos must not see the repo the tests run in (e.g. from a git hook) or the user's config.
// makeGitRepo passes its own user.name and user.email.
for (const name of ["GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE"]) delete process.env[name];
process.env.GIT_CONFIG_GLOBAL = "/dev/null";
process.env.GIT_CONFIG_NOSYSTEM = "1";
