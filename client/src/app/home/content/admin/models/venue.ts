import { Stand } from './stand';
import { Reservation } from 'src/app/views/admin/reservations/reservation/reservation';
import { Event } from 'app/models/event';
import { Company } from 'app/models/company';

export class Venue {
    edition: String;
    image: String;
    stands: Stand[];

    constructor(edition: String, image: String) {
        this.edition = edition;
        this.image = image;
    }
}

export class Availability {
    venue?: Venue;
    availability: [{
        day: number;
        stands: [{
            id: number;
            free: boolean;
            company?: Company;
        }]
    }];

    constructor(availability: Availability) {
        this.venue = availability.venue;
        this.availability = availability.availability;
    }

    static generate(event: Event, venue: Venue, reservations: Reservation[], companies: Company[]) {
        const result = {
            venue: venue,
            availability: [] as {
                day: number;
                stands: [{
                    id: number;
                    free: boolean;
                    company?: Company;
                }]
            }[]
        };

        const stands = venue.stands.map(stand => {
            return {
                id: stand.id,
                free: true
            };
        });

        for (let day = 1; day <= event.getDuration(); day++) {
            result.availability.push({
                day: day,
                stands: Array.from(stands) as [{ id: number; free: boolean; company?: Company; }]
            });
        }

        const availability = new Availability(result as Availability);
        availability.fillReservations(reservations, companies);

        return availability;
    }

    fillReservations(reservations: Reservation[], companies: Company[]) {
        const confirmed = reservations.filter(r => r.isConfirmed());

        for (const reservation of confirmed) {
            for (const stand of reservation.stands) {
                const day = this.availability
                    .map(av => av.day).indexOf(stand.day);

                const selectedStand = this.availability[day].stands
                    .map(s => s.id).indexOf(stand.standId);

                this.availability[day].stands[selectedStand] = {
                    id: stand.standId,
                    free: false,
                    company: Company.findById(reservation.companyId, companies)
                };
            }
        }
    }

    isFree(selectedDay: number, standId: number): boolean {
        const availability = this.availability;
        const day = availability.filter(_day => _day.day === selectedDay);

        if (day.length === 0) { return false; }

        const stands = day[0].stands;

        const stand = stands.filter(_stand => _stand.id === standId);

        return stand.length === 0 ? false : stand[0].free;
    }
}
