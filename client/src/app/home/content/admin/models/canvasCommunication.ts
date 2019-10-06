import { Stand } from './stand';
import { Reservation, Stand as ReservationStand } from 'src/app/views/admin/reservations/reservation/reservation';
import { Availability, Venue } from 'src/app/views/admin/venues/venue/venue';

export enum CanvasState {
    VENUE, RESERVATIONS, COMPANY_RESERVATIONS
}

export enum CanvasAction {
    SETUP, ON, OFF, REVERT, CLEAR, SELECT, SELECT_TO_DELETE, SELECT_DAY
}

export class Selected {
    stand?: Stand;
    day?: number;
}

export class CanvasActionCommunication {
    action: CanvasAction;
    selected: Selected;

    constructor(action: CanvasAction, selected?: Selected) {
        this.action = action;
        this.selected = selected;
    }
}

export class CanvasData {
    static COLOR_DEFAULT = { DEFAULT: '#00386f', SELECTED: '#5ee0ff' };
    static COLOR_DELETE = { DEFAULT: '#dc2121' };
    static COLOR_OCCUPIED = { DEFAULT: '#ffffff00', SELECTED: '#dc2121' };
    static COLOR_FREE = { DEFAULT: '#ffffff00', SELECTED: '#34ca34' };
    static COLOR_RESERVATION = { PENDING: '#e8e850', CANCELLED: '#ff0000', CONFIRMED: '#5ee0ff' };
    static NO_COLOR = '#00000000';

    state: CanvasState;
    availability: { value: Availability; selectedDay: number; };
    reservation: Reservation;
    stands: Stand[];
    pendingStand: Stand;

    constructor(state: CanvasState) {
        this.state = state;
        this.availability = { value: undefined, selectedDay: undefined };
    }

    updateStands(venue: Venue) {
        this.stands = venue.stands;
        this.pendingStand = undefined;
    }

    clear() {
        this.pendingStand = undefined;
        this.availability = undefined;
        this.reservation = undefined;
    }

    getColor(stand: Stand, selected?: boolean): string {
        switch (this.state) {
            case CanvasState.VENUE:
                return selected ? CanvasData.COLOR_DEFAULT.SELECTED : CanvasData.COLOR_DEFAULT.DEFAULT;

            case CanvasState.COMPANY_RESERVATIONS:
                return this.availability && this.availability.selectedDay
                    ? this.getColorFromCompanyReservationsState(stand, selected)
                    : CanvasData.NO_COLOR;

            case CanvasState.RESERVATIONS:
                return this.availability && this.availability.selectedDay && this.availability.value
                    ? this.getColorFromReservationsState(stand, selected)
                    : CanvasData.NO_COLOR;

            default:
                return CanvasData.NO_COLOR;
        }
    }

    private colorFromReservation(): string {
        if (this.reservation.feedback) {
            if (this.reservation.feedback.status === 'CANCELLED') {
                return CanvasData.COLOR_RESERVATION.CANCELLED;
            }

            if (this.reservation.feedback.status === 'CONFIRMED') {
                return CanvasData.COLOR_RESERVATION.CONFIRMED;
            }

            return CanvasData.COLOR_RESERVATION.PENDING;
        } else {
            return CanvasData.COLOR_RESERVATION.PENDING;
        }
    }

    private getColorFromReservationsState(stand: Stand, selected?: boolean): string {
        const free = this.availability.value.isFree(
            this.availability.selectedDay, stand.id
        );

        if (selected) {
            return free ? CanvasData.COLOR_FREE.SELECTED : CanvasData.COLOR_DEFAULT.SELECTED;
        } else {
            return free ? CanvasData.NO_COLOR : CanvasData.COLOR_DEFAULT.DEFAULT;
        }
    }

    private getColorFromCompanyReservationsState(stand: Stand, selected?: boolean): string {
        const s = new ReservationStand(this.availability.selectedDay, stand.id);

        if (this.reservation && this.reservation.hasStand(s)) {
            return this.colorFromReservation();
        }

        if (this.availability.value) {

            const free = this.availability.value.isFree(
                this.availability.selectedDay, stand.id
            );

            if (selected) {
                return free ? CanvasData.COLOR_FREE.SELECTED : CanvasData.COLOR_OCCUPIED.SELECTED;
            } else {
                return free ? CanvasData.COLOR_FREE.DEFAULT : CanvasData.COLOR_OCCUPIED.DEFAULT;
            }
        }
    }
}
