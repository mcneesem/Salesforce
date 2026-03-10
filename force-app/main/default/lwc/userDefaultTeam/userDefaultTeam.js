import { LightningElement , api } from "lwc";

const DEFAULT_PAGE_SIZE = 5;

export default class UserDefaultTeam extends LightningElement {
    // Public API
    @api titlePrefix = "Team";
    @api columns = [];

    // sorting (read-only table; no selection or row actions)
    sortedBy = "userName";
    sortedDirection = "asc";
    showAll = false;

    // Title getter
    get title() {
        return `${this.titlePrefix} (${this.total})`;
    }

    // total records helper...
    get total() {
        return ( this.rows ? this.rows.length : 0 );
    }

    // rows to render (either limited by pageSize or all)
    get pagedRows() {
        let result = [];
        if ( this.showAll ) {
            result = this.rows;
        } else {
            result = this.rows?.slice( 0 , this.pageSize );
        }
        return result;
    }

    // "View All" link state
    get isViewAllDisabled() {
        return ( ( this.total === 0 ) || ( this.showAll === true ) );
    }

    // private page size attribute...
    _pageSize = DEFAULT_PAGE_SIZE;
    // public (api) page size accessors...
    @api
    get pageSize() {
        return this._pageSize;
    }
    set pageSize( value ) {
        let parsed = DEFAULT_PAGE_SIZE;
        if ( value ) {
            parsed = Number( value );
        }
        if ( !parsed || !Number.isFinite( parsed ) || ( parsed < 1 ) ) {
            parsed = DEFAULT_PAGE_SIZE;
        }
        this._pageSize = parsed;
    }

    // private rows attribute...
    _rows = [];
    // public (api) rows accessors...
    @api
    get rows() {
        return this._rows;
    }
    set rows( value ) {
        try {
            if ( Array.isArray( value ) && ( value.length > 0 ) ) {
                // Ensure objects and defensive defaults
                const sanitized = value.map( ( dataRow ) => ( { ...dataRow } ) );
                this._rows = this.sortData( sanitized , this.sortedBy , this.sortedDirection );
                this.errorMessage = undefined;
                this.showAll = false;
            } else {
                this.errorMessage = undefined;
                this._rows = [];
            }
        } catch ( ex ) {
            this.error = ex?.message;
        }
    }

    // private error attribute...
    errorMessage;
    // public (api) error accessors...
    @api
    get error() {
        return this.errorMessage;
    }
    set error( message ) {
        let msg = "UNKNOWN ERROR";
        if ( ( typeof message === 'string' ) && ( message.length > 0 ) ) {
            msg = message;
        }
        this.errorMessage = msg;
        this.rows = [];
    }

    // Handlers

    handleViewAll() {
        if ( !this.isViewAllDisabled ) {
            this.showAll = true;
        }
    }

    handleSort( event ) {
        const detail = ( event?.detail || null );
        const sortField = ( ( typeof detail?.fieldName === "string" ) ? detail.fieldName : undefined );
        const sortDirection = ( ( typeof detail?.sortDirection === "string" ) ? detail.sortDirection : undefined );
        let changed = false;
        if ( sortField
            && sortDirection
            && ( ( sortField !== this.sortedBy ) || ( sortDirection !== this.sortedDirection ) )
            )
        {
            this.sortedBy = sortField;
            this.sortedDirection = sortDirection;
            this.rows = this.sortData( this.rows , this.sortedBy , this.sortedDirection );
            changed = true;
        }
        return changed;
    }

    // Helpers

    sortData( rowsToSort , sortField , sortDirection ) {
        let result = rowsToSort;
        if ( sortField ) {
            const directionMultiplier = ( ( sortDirection === "desc" ) ? -1 : 1 );
            result = [...rowsToSort].sort((rowA, rowB) => {
                const valueA = (rowA?.[sortField]?.toString() || "").toLowerCase();
                const valueB = (rowB?.[sortField]?.toString() || "").toLowerCase();
                let returnValue = 0;
                if ( valueA > valueB ) {
                    returnValue = directionMultiplier;
                } else if ( valueA < valueB ) {
                    returnValue = -directionMultiplier;
                }
                return returnValue;
            });
        }
        return result;
    }

}
//