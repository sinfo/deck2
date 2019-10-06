import { Pipe, PipeTransform } from '@angular/core';

import { Event } from 'src/app/models/event';

@Pipe({
  name: 'getArrayOfParticipationDays'
})
export class GetArrayOfParticipationDaysPipe implements PipeTransform {

  transform(event: Event): number[] {
    const duration = event.duration.getDate();
    const result = [] as number[];

    for (let day = 1; day <= duration; day += 1) {
      result.push(day);
    }

    return result;
  }

}
