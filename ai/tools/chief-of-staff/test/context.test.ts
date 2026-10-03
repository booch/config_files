import { afterEach, expect, test } from "bun:test";
import { realRunner } from "../src/context";

afterEach(() => {
    delete process.env.CHIEF_TEST_PROBE;
});

// Bun.spawn otherwise sees the environment the process started with, so test/setup.ts could
// not keep test git away from an outer repo's GIT_DIR or the user's git config.
test("realRunner hands commands the current environment", async () => {
    process.env.CHIEF_TEST_PROBE = "current";
    const result = await realRunner(["sh", "-c", 'printf %s "$CHIEF_TEST_PROBE"']);
    expect(result.stdout).toBe("current");
});
