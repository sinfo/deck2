import { Pipe, PipeTransform } from '@angular/core';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
import { Member } from '../models/member';

@Pipe({
    name: 'highlightTags'
})
export class HighlightTagsPipe implements PipeTransform {

    private pattern = /@[a-zA-Z0-9\.]+/ig;
    private addedCharacters = 0;

    constructor(private _sanitizer: DomSanitizer) { }

    private wrap(text: string, tag: string, position: number): string {
        const prefix = text.substring(0, this.addedCharacters + position);
        const sufix = text.substring(this.addedCharacters + position + tag.length);

        const prepended = '<span style="color: var(--font-tertiary)">';
        const appended = '</span>';

        this.addedCharacters += prepended.length + appended.length;

        return prefix + prepended + tag + appended + sufix;
    }

    transform(text: string, members: Member[]): SafeHtml {
        let result = text;
        if (!members) { return text; }

        let match;
        while ((match = this.pattern.exec(text)) !== null) {
            for (const member of members) {
                if (member.sinfoid === match[0].substring(1)) {
                    result = this.wrap(result, match[0], match.index);
                    break;
                }
            }
        }

        return this._sanitizer.bypassSecurityTrustHtml(result);
    }

}
