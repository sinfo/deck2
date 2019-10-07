import { Pipe, PipeTransform } from '@angular/core';

@Pipe({
    name: 'parseStatus'
})
export class ParseStatusPipe implements PipeTransform {

    transform(status: string): any {
        return status.split('_').join(' ');
    }

}
