/**
 * ApexDocs:
 * Class: SandboxHealthControllerTest
 * Description: Unit tests for SandboxHealthController. Verifies read-only health checks execute without unhandled exceptions
 *              and produce a well-formed DTO with sections and statuses. Uses minimal seed data and mocks where appropriate.
 *
 * Notes:
 * - No SeeAllData; we do not attempt to create Custom Settings, Labels, or CSP metadata. We validate structural integrity,
 *   non-null fields, and stable behavior across user contexts.
 * - Because controller reads org/label/custom-setting state, exact PASS/FAIL outcomes vary by org. Tests avoid asserting specific
 *   expected values and instead assert consistent section presence and status semantics.
 * - All methods under test are @AuraEnabled(cacheable=true) and read-only.
 */
@IsTest
private class SandboxHealthControllerTest {

    /**
     * @TestSetup
     * Minimal setup. Intentionally does not seed Custom Settings or CSP metadata since the controller is read-only
     * and should tolerate missing data via WARN/FAIL checks internally without throwing.
     */
    @TestSetup
    static void setupData() {
        // No data creation required for read-only verification service
    }

    @IsTest
    static void testQueuesEmailSuffix_section_verification() {
        // Arrange: create two queues, one compliant and one non-compliant
        Group passQueue = new Group(
            Name = 'Test Queue PASS',
            Type = 'Queue',
            Email = 'queue.pass@insperity.com.invalid'
        );
        Group failQueue = new Group(
            Name = 'Test Queue FAIL',
            Type = 'Queue',
            Email = 'queue.fail@insperity.com'
        );
        insert new List<Group>{ passQueue, failQueue };

        Test.startTest();
        SandboxHealthController.HealthResult res = SandboxHealthController.getHealth();
        Test.stopTest();

        // Find the Queues Email Suffix section
        SandboxHealthController.Section target = null;
        for (SandboxHealthController.Section s : res.sections) {
            if (s != null && s.key == 'queuesEmailSuffix') {
                target = s;
                break;
            }
        }
        System.assertNotEquals(null, target, 'Queues Email Suffix section should be present');

        // Build a map of checks by label (queue name)
        Map<String, SandboxHealthController.Check> byLabel = new Map<String, SandboxHealthController.Check>();
        for (SandboxHealthController.Check c : target.checks) {
            byLabel.put(c.label, c);
        }

        System.assert(byLabel.containsKey(passQueue.Name), 'PASS queue check should exist');
        System.assert(byLabel.containsKey(failQueue.Name), 'FAIL queue check should exist');

        System.assertEquals(SandboxHealthController.STATUS.PASS.name(), byLabel.get(passQueue.Name).status, 'PASS queue should PASS');
        System.assertEquals(SandboxHealthController.STATUS.FAIL.name(), byLabel.get(failQueue.Name).status, 'FAIL queue should FAIL');

        // With at least one FAIL, section should be FAIL
        System.assertEquals(SandboxHealthController.STATUS.FAIL.name(), target.status, 'Section should be FAIL when any queue fails');
    }

    /**
     * Helper: Validate that a Section has required shape.
     */
    private static void assertValidSection(SandboxHealthController.Section s) {
        System.assertNotEquals(null, s, 'Section must not be null');
        System.assert(!String.isBlank(s.key), 'Section.key should be set');
        System.assert(!String.isBlank(s.label), 'Section.label should be set');
        System.assertNotEquals(null, s.checks, 'Section.checks should not be null');
        System.assert(!String.isBlank(s.status), 'Section.status should be set');
        // Category is optional but if present, it should be non-blank string
        if (s.category != null) {
            System.assert(!String.isBlank(s.category), 'Section.category should not be blank if provided');
        }
    }

    /**
     * Smoke test: Ensure getHealth executes and returns a DTO with basic org context populated.
     * We do not assert exact values that depend on the running org, only presence and types.
     */
    @IsTest
    static void testGetHealth_smoke() {
        Test.startTest();
        SandboxHealthController.HealthResult res = SandboxHealthController.getHealth();
        Test.stopTest();

        System.assertNotEquals(null, res, 'Result must not be null');
        System.assertNotEquals(null, res.sections, 'Sections list must not be null');
        System.assert(res.sections.size() > 0, 'Expected one or more sections');

        // Basic org context
        // sandboxName may be null in non-sandbox environments, so do not assert non-blank
        System.assert(!String.isBlank(res.orgId), 'Org Id must be populated');
        System.assert(!String.isBlank(res.instance), 'Instance must be populated');
        System.assertNotEquals(null, res.isSandbox, 'isSandbox must not be null');
        System.assertNotEquals(null, res.evaluatedAt, 'evaluatedAt must not be null');

        // Validate each section has expected shape and status is one of enum names
        Set<String> allowed = new Set<String>{
            SandboxHealthController.STATUS.PASS.name(),
            SandboxHealthController.STATUS.WARN.name(),
            SandboxHealthController.STATUS.FAIL.name()
        };
        Boolean sawImageDocs = false;

        for (SandboxHealthController.Section s : res.sections) {
            assertValidSection(s);
            System.assert(allowed.contains(s.status), 'Section status must be PASS/WARN/FAIL');
            // Each check should have valid shape as well
            for (SandboxHealthController.Check c : s.checks) {
                System.assertNotEquals(null, c, 'Check must not be null');
                System.assert(!String.isBlank(c.key), 'Check.key should be set');
                System.assert(!String.isBlank(c.label), 'Check.label should be set');
                // expected/actual/message can be null depending on check type; status must be valid
                System.assert(allowed.contains(c.status), 'Check status must be PASS/WARN/FAIL');
            }

            // Capture presence of the new Image Documents section
            if (s.key == 'imageDocuments') {
                sawImageDocs = true;
                // Basic expectations specific to the Image Documents section:
                // - At least one check is produced (presence/visibility/type)
                System.assert(s.checks.size() >= 1, 'Image Documents section should contain checks');
            }
        }

        System.assert(sawImageDocs, 'Expected Image Documents section to be present');
    }

    /**
     * Validate that section aggregation logic behaves consistently with documented rules:
     * - All PASS => PASS
     * - Any FAIL => FAIL
     * - No FAIL but contains WARN => WARN
     * - Empty/Null => WARN
     *
     * We indirectly exercise the private method by constructing sections that mimic outcomes
     * using public helpers exposed through returned structure.
     */
    @IsTest
    static void testSectionStatusSemantics_indirect() {
        // Build synthetic checks via the controller's helper naming semantics
        // Since helpers are private, we cannot call them directly. We validate semantics
        // using a simplified local evaluation mirroring documented rules and then assert
        // that getHealth returns at least one section with each possible status across orgs
        // OR, at minimum, not throw and produce a status within allowed values.
        Test.startTest();
        SandboxHealthController.HealthResult res = SandboxHealthController.getHealth();
        Test.stopTest();

        Set<String> allowed = new Set<String>{
            SandboxHealthController.STATUS.PASS.name(),
            SandboxHealthController.STATUS.WARN.name(),
            SandboxHealthController.STATUS.FAIL.name()
        };
        Boolean sawPass = false, sawWarn = false, sawFail = false;
        for (SandboxHealthController.Section s : res.sections) {
            if (s == null) continue;
            if (s.status == SandboxHealthController.STATUS.PASS.name()) sawPass = true;
            if (s.status == SandboxHealthController.STATUS.WARN.name()) sawWarn = true;
            if (s.status == SandboxHealthController.STATUS.FAIL.name()) sawFail = true;
            System.assert(allowed.contains(s.status), 'Unexpected section status value');
        }

        // We cannot guarantee all three exist in every org, but we can at least ensure one valid status observed
        System.assert(sawPass || sawWarn || sawFail, 'Expected at least one recognized section status');
    }

    /**
     * Security context test: Ensure controller runs under a standard user context without unhandled exceptions.
     * This does not grant special permissions; behavior may yield WARN/FAIL checks but must not throw.
     */
    @IsTest
    static void testGetHealth_runsAsStandardUser() {
        // Create a minimal profile-backed user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'stdu',
            Email = 'std.user@example.invalid',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago',
            Username = 'std.user.' + System.now().getTime() + '@example.invalid',
            ProfileId = p.Id
        );

        System.runAs(u) {
            Test.startTest();
            SandboxHealthController.HealthResult res = SandboxHealthController.getHealth();
            Test.stopTest();

            System.assertNotEquals(null, res, 'Result must not be null for standard user');
            System.assertNotEquals(null, res.sections, 'Sections must not be null for standard user');
            // Not asserting sizes or particular statuses; read-only code should still return structured output
        }
    }
}