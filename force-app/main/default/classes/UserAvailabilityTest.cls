
@isTest
private class UserAvailabilityTest {

    // Utility to build a DateTime on a given day with hour/minute (24h)
    private static Datetime dt(Integer year, Integer month, Integer day, Integer hour, Integer minute) {
        Date d = Date.newInstance(year, month, day);
        Time t = Time.newInstance(hour, minute, 0, 0);
        return Datetime.newInstance(d, t);
    }

    // Format helper to mirror UserAvailability.toString(Event)
    private static String fmt(Datetime startDt, Integer minutes) {
        Datetime endDt = startDt.addMinutes(minutes);
        return startDt.format('yyyy-MM-dd HH:mm') + ' - ' + endDt.format('HH:mm');
    }

    @isTest
    private static void returnsNullWhenWindowIsNull() {
        Test.startTest();
        UserAvailability svc = new UserAvailability();
        List<String> result = svc.getAvailableSlots(new List<Event>(), null, 15);
        Test.stopTest();

        System.assertEquals(null, result, 'When window is null, should return null.');
    }

    @isTest
    private static void emptyRecordsReturnsFullWindowSplitByStep() {
        Datetime start = dt(2025, 1, 1, 9, 0);
        Datetime endTime = dt(2025, 1, 1, 10, 0);

        Event window = new Event(StartDateTime = start, EndDateTime = endTime);

        Test.startTest();
        UserAvailability svc = new UserAvailability();
        List<String> result = svc.getAvailableSlots(new List<Event>(), window, 15);
        Test.stopTest();

        // Expect 4 slots: 9:00-9:15, 9:15-9:30, 9:30-9:45, 9:45-10:00
        List<String> expected = new List<String>{
            fmt(start, 15),
            fmt(start.addMinutes(15), 15),
            fmt(start.addMinutes(30), 15),
            fmt(start.addMinutes(45), 15)
        };

        System.assertNotEquals(null, result, 'Should not return null when window is provided.');
        System.assertEquals(expected.size(), result.size(), 'Should split full hour into 4 slots at 15-minute steps.');
        System.assertEquals(expected, result, 'Slots should match full window in 15-minute increments.');
    }

    @isTest
    private static void singleBusyInsideWindowNoBuffer() {
        // Window: 9:00 - 10:00
        Datetime winStart = dt(2025, 1, 1, 9, 0);
        Datetime winEnd = dt(2025, 1, 1, 10, 0);
        Event window = new Event(StartDateTime = winStart, EndDateTime = winEnd);

        // Busy: 9:20 - 9:30, buffer 10 min => adjusted busy: 9:10 - 9:40
        Event busy = new Event(StartDateTime = dt(2025, 1, 1, 9, 20), EndDateTime = dt(2025, 1, 1, 9, 30));
        Integer step = 10;

        Test.startTest();
        UserAvailability svc = new UserAvailability();
        List<String> result = svc.getAvailableSlots(new List<Event>{ busy }, window, step);
        Test.stopTest();

        // Available slots in 10-min steps excluding only 9:20-9:30:
        // Window slots: [9:00-9:10], [9:10-9:20], [9:20-9:30], [9:30-9:40], [9:40-9:50], [9:50-10:00]
        // Remove [9:20-9:30]
        List<String> expected = new List<String>{
            fmt(winStart, 10),
            fmt(dt(2025, 1, 1, 9, 10), 10),
            fmt(dt(2025, 1, 1, 9, 30), 10),
            fmt(dt(2025, 1, 1, 9, 40), 10),
            fmt(dt(2025, 1, 1, 9, 50), 10)
        };

        System.assertEquals(expected, result, 'Available slots should exclude only the actual busy range.');
    }

    @isTest
    private static void busyOverlappingWindowEdgesAreClamped() {
        // Window: 9:00 - 10:00
        Datetime winStart = dt(2025, 1, 1, 9, 0);
        Datetime winEnd = dt(2025, 1, 1, 10, 0);
        Event window = new Event(StartDateTime = winStart, EndDateTime = winEnd);

        // Busy1 starts before window: 8:30-9:15 (with buffer 0) -> clamped to 9:00-9:15
        Event b1 = new Event(StartDateTime = dt(2025, 1, 1, 8, 30), EndDateTime = dt(2025, 1, 1, 9, 15));
        // Busy2 ends after window: 9:50-10:30 -> clamped to 9:50-10:00
        Event b2 = new Event(StartDateTime = dt(2025, 1, 1, 9, 50), EndDateTime = dt(2025, 1, 1, 10, 30));

        Test.startTest();
        UserAvailability svc = new UserAvailability();
        List<String> result = svc.getAvailableSlots(new List<Event>{ b1, b2 }, window, 10);
        Test.stopTest();

        // Window slots at 10-min steps: 9:00-9:10, 9:10-9:20, 9:20-9:30, 9:30-9:40, 9:40-9:50, 9:50-10:00
        // Remove clamped busy: 9:00-9:10, 9:10-9:20 (from b1); 9:50-10:00 (from b2)
        List<String> expected = new List<String>{
            fmt(dt(2025, 1, 1, 9, 15), 10),
            fmt(dt(2025, 1, 1, 9, 25), 10),
            fmt(dt(2025, 1, 1, 9, 35), 10)
        };

        System.assertEquals(expected, result, 'Slots overlapping window edges should be removed after clamping.');
    }

    @isTest
    private static void overlappingBusyEventsAreFused() {
        // Window: 9:00 - 10:00
        Datetime winStart = dt(2025, 1, 1, 9, 0);
        Datetime winEnd = dt(2025, 1, 1, 10, 0);
        Event window = new Event(StartDateTime = winStart, EndDateTime = winEnd);

        // Overlapping busies (after optional buffers they still overlap):
        // b1: 9:10-9:25, b2: 9:20-9:40 => fused busy 9:10-9:40
        Event b1 = new Event(StartDateTime = dt(2025, 1, 1, 9, 10), EndDateTime = dt(2025, 1, 1, 9, 25));
        Event b2 = new Event(StartDateTime = dt(2025, 1, 1, 9, 20), EndDateTime = dt(2025, 1, 1, 9, 40));

        Test.startTest();
        UserAvailability svc = new UserAvailability();
        List<String> result = svc.getAvailableSlots(new List<Event>{ b1, b2 }, window, 10);
        Test.stopTest();

        // After fusion, available: [9:00-9:10], [9:40-9:50], [9:50-10:00]
        List<String> expected = new List<String>{
            fmt(winStart, 10),
            fmt(dt(2025, 1, 1, 9, 40), 10),
            fmt(dt(2025, 1, 1, 9, 50), 10)
        };

        System.assertEquals(expected, result, 'Overlapping busy events must be merged before availability computation.');
    }

    @isTest
    private static void stepSizeRespectedThirtyMinutes() {
        // Window: 9:00 - 10:00, step = 30 -> [9:00-9:30], [9:30-10:00]
        Event window = new Event(
            StartDateTime = dt(2025, 1, 1, 9, 0),
            EndDateTime = dt(2025, 1, 1, 10, 0)
        );

        Test.startTest();
        UserAvailability svc = new UserAvailability();
        List<String> result = svc.getAvailableSlots(new List<Event>(), window, 30);
        Test.stopTest();

        List<String> expected = new List<String>{
            fmt(dt(2025, 1, 1, 9, 0), 30),
            fmt(dt(2025, 1, 1, 9, 30), 30)
        };

        System.assertEquals(expected, result, 'Step size of 30 minutes should split the window accordingly.');
    }

    @isTest
    private static void nullBufferAndNullStepsDefaulting() {
        // Window: 9:00 - 9:31, null steps => defaults to 1 minute
        Event window = new Event(
            StartDateTime = dt(2025, 1, 1, 9, 0),
            EndDateTime = dt(2025, 1, 1, 9, 31)
        );
        // Single busy 9:10-9:12, buffer null => default 0
        Event busy = new Event(StartDateTime = dt(2025, 1, 1, 9, 10), EndDateTime = dt(2025, 1, 1, 9, 12));

        Test.startTest();
        UserAvailability svc = new UserAvailability();
        List<String> result = svc.getAvailableSlots(new List<Event>{ busy }, window, null);
        Test.stopTest();

        // With 1-min splits, the unavailable minutes are [9:10-9:11] and [9:11-9:12].
        // So count = 31 total minutes - 2 busy minutes = 29 available slots.
        System.assertNotEquals(null, result, 'Result should not be null for provided window.');
        System.assertEquals(29, result.size(), 'Null steps should default to 1 minute increments; two minutes should be excluded.');
        // Spot-check a few expected slots exist and excluded ones don&#39;t
        System.assert(result.contains(fmt(dt(2025, 1, 1, 9, 0), 1)), '9:00-9:01 should be available.');
        System.assert(!result.contains(fmt(dt(2025, 1, 1, 9, 10), 1)), '9:10-9:11 should be excluded.');
        System.assert(!result.contains(fmt(dt(2025, 1, 1, 9, 11), 1)), '9:11-9:12 should be excluded.');
        System.assert(result.contains(fmt(dt(2025, 1, 1, 9, 30), 1)), '9:30-9:31 should be available.');
    }
}