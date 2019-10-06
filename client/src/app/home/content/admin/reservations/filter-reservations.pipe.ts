import { Pipe, PipeTransform } from '@angular/core';
import { Reservation } from 'src/app/views/admin/reservations/reservation/reservation';

@Pipe({
  name: 'filterReservations'
})
export class FilterReservationsPipe implements PipeTransform {

  transform(reservations: Reservation[], reservation?: Reservation): Reservation[] {
    return reservation && reservation instanceof Reservation
      ? reservations.filter(r => r.companyId === reservation.companyId) as Reservation[]
      : reservations;
  }

}
