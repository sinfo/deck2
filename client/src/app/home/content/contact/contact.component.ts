import { Component, OnInit, Input } from '@angular/core';

import { ThemeService } from '../../../theme.service';

import { Contact } from '../../../models/contact';
import { Theme } from '../../../theme';

@Component({
    selector: 'app-contact',
    templateUrl: './contact.component.html',
    styleUrls: ['./contact.component.css']
})
export class ContactComponent implements OnInit {

    darkMode: boolean;

    @Input() contact: Contact;

    constructor(
        private themeService: ThemeService
    ) { }

    ngOnInit() {
        const result = this.themeService.getThemeSubscription();
        this.darkMode = result.active.dark;
        result.subscription.subscribe((theme: Theme) => {
            this.darkMode = theme.dark;
        });
    }

}
