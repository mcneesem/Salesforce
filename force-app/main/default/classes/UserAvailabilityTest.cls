@isTest
private class UserAvailabilityTest {

    // Utility to build a DateTime on a given day with hour/minute (24h)
    private static Datetime dt(
        Integer year ,
        Integer month ,
        Integer day ,
        Integer hour ,
        Integer minute
        )
    {
        Date d = Date.newInstance(year, month, day);
        Time t = Time.newInstance(hour, minute, 0, 0);
        return Datetime.newInstance(d, t);
    }

    // Helper to construct an Event slot from start and minutes
    private static Event evt(Datetime startDt, Integer minutes) {
        return new Event(StartDateTime = startDt, EndDateTime = startDt.addMinutes(minutes));
    }
    // Helper to compare two Events by Start and End
    private static void assertEventEquals(Event expected, Event actual, String msg) {
        System.assertNotEquals(null, actual, msg + ' actual should not be null');
        System.assertEquals(expected.StartDateTime, actual.StartDateTime, msg + ' start mismatch');
        System.assertEquals(expected.EndDateTime, actual.EndDateTime, msg + ' end mismatch');
    }
    private static void assertEventListEquals(List<Event> expected, List<Event> actual, String msg) {
        System.assertEquals(expected.size(), actual.size(), msg + ' size mismatch');
        for (Integer i = 0; i < expected.size(); i++) {
            assertEventEquals(expected[i], actual[i], msg + ' at index ' + i);
        }
    }
    private static Boolean containsEvent(List<Event> evts, Event probe) {
        for (Event e : evts) {
            if (e.StartDateTime == probe.StartDateTime && e.EndDateTime == probe.EndDateTime) {
                return true;
            }
        }
        return false;
    }

    @isTest
    private static void returnsNullWhenWindowIsNull() {
        Test.startTest();
        UserAvailability svc = new UserAvailability();
        List<Event> result = svc.getAvailableSlots(new List<Event>(), null, 15);
        Test.stopTest();

        System.assertEquals(null, result, 'When window is null, should return null.');
    }

    @isTest
    private static void emptyRecordsReturnsFullWindowSplitByStep() {
        Datetime start = dt(2025, 1, 2, 9, 0);
        Datetime endTime = dt(2025, 1, 2, 10, 0);

        Event window = new Event(StartDateTime = start, EndDateTime = endTime);

        Test.startTest();
        UserAvailability svc = new UserAvailability();
        List<Event> result = svc.getAvailableSlots(new List<Event>(), window, 15);
        Test.stopTest();

        // Expect 4 slots: 9:00-9:15, 9:15-9:30, 9:30-9:45, 9:45-10:00
        List<Event> expected = new List<Event>{
            evt(start, 15),
            evt(dt(2025, 1, 2, 9, 15), 15),
            evt(dt(2025, 1, 2, 9, 30), 15),
            evt(dt(2025, 1, 2, 9, 45), 15)
        };

        System.assertNotEquals(null, result, 'Should not return null when window is provided.');
        assertEventListEquals(expected, result, 'Should split full hour into 4 slots at 15-minute steps.');
    }

    @isTest
    private static void singleBusyInsideWindowNoBuffer() {
        // Window: 9:00 - 10:00
        Datetime winStart = dt(2025, 1, 2, 9, 0);
        Datetime winEnd = dt(2025, 1, 2, 10, 0);
        Event window = new Event(StartDateTime = winStart, EndDateTime = winEnd);

        // Busy: 9:20 - 9:30
        Event busy = new Event(StartDateTime = dt(2025, 1, 2, 9, 20), EndDateTime = dt(2025, 1, 2, 9, 30));
        Integer step = 10;

        Test.startTest();
        UserAvailability svc = new UserAvailability();
        List<Event> result = svc.getAvailableSlots(new List<Event>{ busy }, window, step);
        Test.stopTest();

        // Available slots in 10-min steps excluding only 9:20-9:30:
        List<Event> expected = new List<Event>{
            evt(winStart, 10),
            evt(dt(2025, 1, 2, 9, 10), 10),
            evt(dt(2025, 1, 2, 9, 30), 10),
            evt(dt(2025, 1, 2, 9, 40), 10),
            evt(dt(2025, 1, 2, 9, 50), 10)
        };

        assertEventListEquals(expected, result, 'Available slots should exclude only the actual busy range.');
    }

    @isTest
    private static void busyOverlappingWindowEdgesAreClamped() {
        // Window: 9:00 - 10:00
        Datetime winStart = dt(2025, 1, 2, 9, 0);
        Datetime winEnd = dt(2025, 1, 2, 10, 0);
        Event window = new Event(StartDateTime = winStart, EndDateTime = winEnd);

        // Busy1 starts before window: 8:30-9:15 -> clamped to 9:00-9:15
        Event b1 = new Event(StartDateTime = dt(2025, 1, 2, 8, 30), EndDateTime = dt(2025, 1, 2, 9, 15));
        // Busy2 ends after window: 9:50-10:30 -> clamped to 9:50-10:00
        Event b2 = new Event(StartDateTime = dt(2025, 1, 2, 9, 50), EndDateTime = dt(2025, 1, 2, 10, 30));

        Test.startTest();
        UserAvailability svc = new UserAvailability();
        List<Event> result = svc.getAvailableSlots(new List<Event>{ b1, b2 }, window, 10);
        Test.stopTest();

        // Expected available slots after removing clamped busy intervals
        // Window 9:00-10:00, step 10
        // Clamped busy intervals: [9:00-9:15] and [9:50-10:00]
        // Available slots: [9:15-9:25], [9:25-9:35], [9:35-9:45]
        List<Event> expected = new List<Event>{
            evt(dt(2025, 1, 2, 9, 15), 10),
            evt(dt(2025, 1, 2, 9, 25), 10),
            evt(dt(2025, 1, 2, 9, 35), 10)
        };

        assertEventListEquals(expected, result, 'Slots overlapping window edges should be removed after clamping.');
    }

    @isTest
    private static void overlappingBusyEventsAreFused() {
        // Window: 9:00 - 10:00
        Datetime winStart = dt(2025, 1, 2, 9, 0);
        Datetime winEnd = dt(2025, 1, 2, 10, 0);
        Event window = new Event(StartDateTime = winStart, EndDateTime = winEnd);

        // Overlapping busies:
        // b1: 9:10-9:25, b2: 9:20-9:40 => fused busy 9:10-9:40
        Event b1 = new Event(StartDateTime = dt(2025, 1, 2, 9, 10), EndDateTime = dt(2025, 1, 2, 9, 25));
        Event b2 = new Event(StartDateTime = dt(2025, 1, 2, 9, 20), EndDateTime = dt(2025, 1, 2, 9, 40));

        Test.startTest();
        UserAvailability svc = new UserAvailability();
        List<Event> result = svc.getAvailableSlots(new List<Event>{ b1, b2 }, window, 10);
        Test.stopTest();

        // After fusion, available: [9:00-9:10], [9:40-9:50], [9:50-10:00]
        List<Event> expected = new List<Event>{
            evt(winStart, 10),
            evt(dt(2025, 1, 2, 9, 40), 10),
            evt(dt(2025, 1, 2, 9, 50), 10)
        };

        assertEventListEquals(expected, result, 'Overlapping busy events must be merged before availability computation.');
    }

    @isTest
    private static void stepSizeRespectedThirtyMinutes() {
        // Window: 9:00 - 10:00, step = 30 -> [9:00-9:30], [9:30-10:00]
        Event window = new Event(
            StartDateTime = dt(2025, 1, 2, 9, 0),
            EndDateTime = dt(2025, 1, 2, 10, 0)
        );

        Test.startTest();
        UserAvailability svc = new UserAvailability();
        List<Event> result = svc.getAvailableSlots(new List<Event>(), window, 30);
        Test.stopTest();

        List<Event> expected = new List<Event>{
            evt(dt(2025, 1, 2, 9, 0), 30),
            evt(dt(2025, 1, 2, 9, 30), 30)
        };

        assertEventListEquals(expected, result, 'Step size of 30 minutes should split the window accordingly.');
    }

    @isTest
    private static void nullStepsDefaultingToOneMinute() {
        // Window: 9:00 - 9:31, null steps => defaults to 1 minute
        Event window = new Event(
            StartDateTime = dt(2025, 1, 2, 9, 0),
            EndDateTime = dt(2025, 1, 2, 9, 31)
        );
        // Single busy 9:10-9:12
        Event busy = new Event(StartDateTime = dt(2025, 1, 2, 9, 10), EndDateTime = dt(2025, 1, 2, 9, 12));

        Test.startTest();
        UserAvailability svc = new UserAvailability();
        List<Event> result = svc.getAvailableSlots(new List<Event>{ busy }, window, null);
        Test.stopTest();

        // With 1-min splits, the unavailable minutes are [9:10-9:11] and [9:11-9:12] => 29 available slots.
        System.assertNotEquals(null, result, 'Result should not be null for provided window.');
        System.assertEquals(29, result.size(), 'Null steps should default to 1 minute increments; two minutes should be excluded.');
        System.assert(containsEvent(result, evt(dt(2025, 1, 2, 9, 0), 1)), '9:00-9:01 should be available.');
        System.assert(!containsEvent(result, evt(dt(2025, 1, 2, 9, 10), 1)), '9:10-9:11 should be excluded.');
        System.assert(!containsEvent(result, evt(dt(2025, 1, 2, 9, 11), 1)), '9:11-9:12 should be excluded.');
        System.assert(containsEvent(result, evt(dt(2025, 1, 2, 9, 30), 1)), '9:30-9:31 should be available.');
    }

}
//
