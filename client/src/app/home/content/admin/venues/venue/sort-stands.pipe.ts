import { Pipe, PipeTransform } from '@angular/core';
import { Stand } from '../../models/stand';

@Pipe({
  name: 'sortStands'
})
export class SortStandsPipe implements PipeTransform {

  transform(stands: Stand[], args?: any): Stand[] {
    return stands.sort(Stand.compare);
  }

}
