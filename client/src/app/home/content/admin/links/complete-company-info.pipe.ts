import { Pipe, PipeTransform } from '@angular/core';

import { Company, Participation } from 'src/app/models/company';
import { Event } from 'src/app/models/event';

@Pipe({
  name: 'completeCompanyInfo'
})
export class CompleteCompanyInfoPipe implements PipeTransform {

  transform(simple: Company[], complete: Company[], event?: Event): Company[] {
    const ids: String[] = complete.map(company => company.id);

    return <Company[]>simple.map((company: Company) => {
      const index = ids.indexOf(company.id);

      if (index === -1) { return null; }

      const result = complete[index];

      if (event === undefined) { return result; }

      const participation = Participation.getFromEvent(complete[index].participations, event);

      if (participation) {
        result.currentParticipation = participation;
      }

      return result;
    });
  }

}
