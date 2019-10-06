import { Pipe, PipeTransform } from '@angular/core';
import { Availability } from 'src/app/views/admin/venues/venue/venue';

@Pipe({
  name: 'buildTable'
})
export class BuildTablePipe implements PipeTransform {

  transform(availability: Availability) {
    const duration = Object.keys(availability.availability).length;

    availability.availability.sort((av1, av2) => {
      return av1.day > av2.day ? 1 : 0;
    });

    return availability.venue.stands.map(stand => {
      const result = {
        standId: stand.id,
        days: []
      };

      for (let day = 0; day < duration; day++) {
        const s = availability.availability[day].stands.filter(avStand => avStand.id === stand.id)[0];
        result.days.push({
          free: s.free,
          company: s.company
        });
      }

      return result;
    });
  }

}
