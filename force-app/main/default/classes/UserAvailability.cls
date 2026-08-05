// intentionally `without sharing` to ensure that LWC/scheduleSelle has access to all Event records...
public without sharing class UserAvailability {
    // test w/ UserAvailabilityTest (95%)

    private List<Event> busy = new List<Event>();
    private List<Event> fused = new List<Event>();
    private Integer slotSizeMinutes = 15;

    // find the available time slots within the window of time that do not conflict with the existing Event records...
    public List<Event> getAvailableSlots(
        List<Event> records ,
        Event window ,
        Integer steps
        )
    {
        // reset...
        this.busy = new List<Event>();
        this.fused = new List<Event>();
        // initialize...
        if ( records == null ) {
            records = new List<Event>();
        }
        if ( steps == null ) {
            steps = 1;
        }
        List<Event> available = null;
        if ( window != null ) {
            for ( Event record : records ) {
                if ( ( record.StartDateTime != null )
                    && ( record.EndDateTime != null )
                   )
                {
                    Datetime recordStart = record.StartDateTime;
                    Datetime recordEnd = record.EndDateTime;
                    if ( ( recordStart < window.EndDateTime )
                        && ( recordEnd > window.StartDateTime )
                       )
                    {
                        this.addBusyEvent(
                            new Event(
                                StartDateTime=recordStart ,
                                EndDateTime=recordEnd
                            ) ,
                            window
                        );
                    }
                }
            }
            this.fuseSlots();
            this.slotSizeMinutes = steps;
            available = this.availableSlots( window );
        }
        return available;
    }

    public List<Event> selectEvents( Set<Id> ownerIds , Event window ) {
        List<Event> records = new List<Event>();
        if ( ( ownerIds != null )
            && !ownerIds.isEmpty()
            && ( window != null )
            && ( window.StartDateTime != null )
            && ( window.EndDateTime != null )
            )
        {
            records = [
                SELECT
                    Id ,
                    OwnerId ,
                    StartDateTime ,
                    EndDateTime ,
                    NSP_Event_Subtype__c ,
                    NSP_Event_Type__c
                FROM Event
                WHERE (
                    ( OwnerId IN :ownerIds )
                    AND ( StartDateTime < :window.EndDateTime )
                    AND ( EndDateTime > :window.StartDateTime )
                    AND ( ShowAs != 'Free' )
                )
            ];
        }
        return records;
    }

    //
    //
    //

    private void addBusyEvent( Event b , Event window ) {
        if ( ( this.busy != null )
            && ( b != null )
            && ( b.StartDateTime != null )
            && ( b.EndDateTime != null )
            && ( window != null )
            && ( window.StartDateTime != null )
            && ( window.EndDateTime != null )
            )
        {
            // floor the busy start time to match the window start time...
            if ( window.StartDateTime > b.StartDateTime ) {
                b.StartDateTime = window.StartDateTime;
            }
            // ceiling the busy end time to match the window end time...
            if ( window.EndDateTime < b.EndDateTime ) {
                b.EndDateTime = window.EndDateTime;
            }
            this.busy.add( b );
        }
    }

    private void fuseSlots() {
        if ( this.busy == null ) {
            this.busy = new List<Event>();
        }
        if ( this.fused == null ) {
            this.fused = new List<Event>();
        }
        for ( Event b : this.busy ) {
            Event current = new Event(
                StartDateTime=b.StartDateTime ,
                EndDateTime=b.EndDateTime
            );
            if ( this.fused.isEmpty() ) {
                // add the current busy slot when the fused busy list is empty...
                this.fused.add( current );
            } else {
                // get the last fused busy slot...
                Integer lastIndex = ( this.fused.size() - 1 );
                Event lastFused = this.fused[lastIndex];
                if ( this.isOverlapping( lastFused , current ) ) {
                    //     A: [600-----660)
                    //     B:     [630------720)
                    // FUSED: [600----------720)
                    // set last fused busy end time to the max of current vs last fused...
                    if ( current.EndDateTime > lastFused.EndDateTime ) {
                        lastFused.EndDateTime = current.EndDateTime;
                    }
                    this.fused[lastIndex] = lastFused;
                } else {
                    // add the current busy slot when the there is no overlap with the current fused busy list...
                    this.fused.add( current );
                }
            }
        }
    }

    private Boolean isOverlapping( Event a , Event b ) {
        return ( ( a != null )
            && ( b != null )
            && ( a.StartDateTime != null )
            && ( a.EndDateTime != null )
            && ( b.StartDateTime != null )
            && ( b.EndDateTime != null )
            && ( a.StartDateTime < b.EndDateTime )
            && ( b.StartDateTime < a.EndDateTime )
        );
    }

    // compare the fuzed/merged busy slots to the window for all slots, returning only the available slots, split on the step size in minutes...
    private List<Event> availableSlots( Event window ) {
        List<Event> available = null;
        if ( this.fused == null ) {
            this.fused = new List<Event>();
        }
        if ( this.fused.isEmpty() ) {
            available = this.splitRange( window );
        } else {
            DateTime pointer = window.StartDateTime;
            for ( Event compare : this.fused ) {
                if ( pointer < compare.StartDateTime ) {
                    available = this.splitRange(
                        available ,
                        new Event(
                            StartDateTime=pointer ,
                            EndDateTime=compare.StartDateTime
                        )
                    );
                }
                // set pointer to the max of pointer vs compare.End...
                if ( compare.EndDateTime > pointer ) {
                    pointer = compare.EndDateTime;
                }
            }
            if ( pointer < window.EndDateTime ) {
                available = this.splitRange(
                    available ,
                    new Event(
                        StartDateTime=pointer ,
                        EndDateTime=window.EndDateTime
                    )
                );
            }
        }
        return available;
    }

    // split range into discrete slots...
    private List<Event> splitRange( Event range ) {
        return this.splitRange( null , range );
    }

    private List<Event> splitRange( List<Event> slots , Event range ) {
        if ( slots == null ) {
            slots = new List<Event>();
        }
        if ( ( this.slotSizeMinutes == null ) || ( this.slotSizeMinutes < 1 ) ) {
            this.slotSizeMinutes = 1;
        }
        if ( ( range != null )
            && ( range.StartDateTime != null )
            && ( range.EndDateTime != null )
            )
        {
            DateTime temp = range.StartDateTime;
            while ( temp.addMinutes( this.slotSizeMinutes ) <= range.EndDateTime ) {
                slots.add(
                    new Event(
                        StartDateTime=temp ,
                        EndDateTime=temp.addMinutes( this.slotSizeMinutes )
                    )
                );
                temp = temp.addMinutes( this.slotSizeMinutes );
            }
        }
        return slots;
    }
}
//