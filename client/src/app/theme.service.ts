import {Injectable} from '@angular/core';

import {ReplaySubject} from 'rxjs/internal/ReplaySubject';
import {Observable} from 'rxjs/internal/Observable';

import {StorageService} from './storage.service';

import {dark, light, Theme} from './theme';

const THEME_KEY = 'theme';

@Injectable({
    providedIn: 'root'
})
export class ThemeService {

    private active: Theme;
    private availableThemes: Theme[] = [light, dark];

    private themeSubject: ReplaySubject<Theme> = new ReplaySubject<Theme>();

    constructor(
        private storageService: StorageService
    ) {
        const stored = this.storageService.getItem(THEME_KEY) as { theme: string };

        let set = false;
        if (stored !== null && stored.theme !== undefined) {
            for (const available of this.getAvailableThemes()) {
                if (available.name === stored.theme) {
                    this.setActiveTheme(available);
                    set = true;
                    break;
                }
            }
        }

        if (!set) {
            this.setLightTheme();
        }
    }

    setDarkTheme(): void {
        this.setActiveTheme(dark);
    }

    setLightTheme(): void {
        this.setActiveTheme(light);
    }

    toggleTheme(): void {
        this.isDarkTheme() ? this.setLightTheme() : this.setDarkTheme();
    }

    getThemeSubscription(): { active: Theme, subscription: Observable<Theme> } {
        return {active: this.active, subscription: this.themeSubject.asObservable()};
    }

    private getAvailableThemes(): Theme[] {
        return this.availableThemes;
    }

    private isDarkTheme(): boolean {
        return this.active.name === dark.name;
    }

    private setActiveTheme(theme: Theme): void {
        this.active = theme;

        Object.keys(this.active.properties).forEach(property => {
            document.documentElement.style.setProperty(
                property,
                this.active.properties[property]
            );
        });

        this.storageService.setItem(THEME_KEY, {theme: theme.name});
        this.themeSubject.next(this.active);
    }

}
