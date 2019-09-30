import { Component, ElementRef, Input, OnDestroy, OnInit, ViewChild } from '@angular/core';

import { Subscription } from 'rxjs';

import { MeService } from '../../deck-api/me.service';
import { AuthService } from '../../deck-api/auth.service';
import { ThemeService } from '../../theme.service';

import { Member } from '../../models/member';
import { Notification } from '../../models/notification';
import { Theme } from '../../theme';

@Component({
    selector: 'app-menu',
    templateUrl: './menu.component.html',
    styleUrls: ['./menu.component.css']
})
export class MenuComponent implements OnInit, OnDestroy {

    @Input() me: Member;
    notifications: Notification[];

    darkMode: boolean;

    NIGHT_MODE_MAX = 38;
    DAY_MODE_MAX = 3;

    pos: number;

    // animation vars
    id = null;
    changing_mode = false;

    @ViewChild('nightIcon', { read: ElementRef, static: true }) nightIcon: ElementRef;
    @ViewChild('dayIcon', { read: ElementRef, static: true }) dayIcon: ElementRef;

    private notificationsSubscription: Subscription;

    constructor(
        private authService: AuthService,
        private meService: MeService,
        private themeService: ThemeService
    ) {
    }

    ngOnInit() {
        const notificationsResult = this.meService.subscribeToNotifications(this);
        this.notifications = notificationsResult[0];
        this.notificationsSubscription = notificationsResult[1];

        const themeResult = this.themeService.getThemeSubscription();

        this.darkMode = themeResult.active.dark;
        this.pos = this.darkMode ? this.NIGHT_MODE_MAX : this.DAY_MODE_MAX;

        themeResult.subscription.subscribe((theme: Theme) => {
            this.darkMode = theme.dark;

            this.pos = this.darkMode ? this.NIGHT_MODE_MAX : this.DAY_MODE_MAX;
            this.dayIcon.nativeElement.setAttribute('x', `${this.pos}%`);
            this.nightIcon.nativeElement.setAttribute('x', `${this.pos}%`);
        });
    }

    ngOnDestroy() {
        this.notificationsSubscription.unsubscribe();
    }

    logout() {
        this.authService.logout();
    }

    toggleTheme() {
        this.themeService.toggleTheme();
    }

    changemode() {
        if (this.changing_mode) {
            return;
        }
        this.changing_mode = true;
        this.id = setInterval(() => {
            this.move_icon();
        }, 5);
    }

    move_icon() {
        if (this.pos < this.DAY_MODE_MAX || this.pos > this.NIGHT_MODE_MAX) {
            clearInterval(this.id);
            this.toggleTheme();
            this.changing_mode = false;
            return;
        }

        if (this.darkMode) {
            this.pos--;
        } else {
            this.pos++;
        }

        if (!this.darkMode) {
            this.dayIcon.nativeElement.setAttribute('x', `${this.pos}%`);
        } else {
            this.nightIcon.nativeElement.setAttribute('x', `${this.pos}%`);
        }
    }

}
