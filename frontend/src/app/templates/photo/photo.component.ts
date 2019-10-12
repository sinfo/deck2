import { AfterViewInit, Component, ElementRef, Input, OnInit, QueryList, ViewChildren } from '@angular/core';
import { Role, RoleType } from '../../models/role';

@Component({
    selector: 'app-photo',
    templateUrl: './photo.component.html',
    styleUrls: ['./photo.component.css']
})
export class PhotoComponent implements OnInit, AfterViewInit {

    @ViewChildren('wrapper', { read: ElementRef }) wrappers: QueryList<ElementRef>;

    @Input('status')
    set status(value: String) {
        const options = [
            'SUGGESTED', 'SELECTED', 'ON_HOLD',
            'CONTACTED', 'IN_CONVERSATIONS', 'ACCEPTED',
            'REJECTED', 'GIVEN_UP', 'ANNOUNCED'
        ];

        for (const option of options) {
            if (value === option) {
                this._status = `${value}`;
                break;
            }
        }
    }

    @Input() role: RoleType;

    @Input() setBy: string;
    @Input() url: string;

    _status: string;
    default = 'assets/images/hacky.png';

    constructor() {
    }

    ngOnInit() {
    }

    ngAfterViewInit() {
        this.updateImagesSize();
    }

    updateImagesSize() {
        this.wrappers.forEach((wrapper: ElementRef) => {
            if (this.setBy === 'height' && wrapper.nativeElement.offsetHeight) {
                wrapper.nativeElement.style = `
                    width: ${wrapper.nativeElement.offsetHeight}px;
                    height: ${wrapper.nativeElement.offsetHeight}px;
                `;
            } else if (wrapper.nativeElement.offsetWidth) {
                wrapper.nativeElement.style = `
                    width: ${wrapper.nativeElement.offsetWidth}px;
                    height: ${wrapper.nativeElement.offsetWidth}px;
                `;
            }
        });
    }

    loaded() {
        this.updateImagesSize();
    }

}
