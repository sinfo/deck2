import { AfterViewInit, Directive, ElementRef, HostListener, Input } from '@angular/core';

@Directive({
    selector: '[appSquareImage]'
})
export class SquareImageDirective implements AfterViewInit {

    @Input() setBy: string;

    setByHeight: boolean;

    @HostListener('window:resize')
    onResize() {
        if (this.setByHeight) {
            this.squareByHeight();
        } else {
            this.squareByWidth();
        }
    }

    constructor(private eleRef: ElementRef) {
    }

    squareByHeight() {
        this.eleRef.nativeElement.style = `width: ${this.eleRef.nativeElement.offsetHeight}px`;
    }

    squareByWidth() {
        this.eleRef.nativeElement.style = `height: ${this.eleRef.nativeElement.offsetWidth}px`;
    }

    ngAfterViewInit() {
        if (this.setBy === 'width') {
            this.setByHeight = false;
            this.squareByWidth();
        } else {
            this.setByHeight = true;
            this.squareByHeight();
        }
    }

}
