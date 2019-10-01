import { Injectable } from '@angular/core';
import { HttpHeaders } from '@angular/common/http';
import { Router } from '@angular/router';

import { environment } from 'environments/environment';
import { Credentials } from '../models/credentials';

import { StorageService } from '../storage.service';

@Injectable({
    providedIn: 'root'
})
export class AuthService {

    private deck2: String = environment.deck2;

    constructor(
        private storage: StorageService,
        private router: Router
    ) { }

    saveCredentials(credentials: Credentials) {
        this.storage.setItem('credentials', credentials);
    }

    login() {
        window.location.href = `${this.deck2}/auth/login`;
    }

    logout() {
        this.storage.removeItem('credentials');
        this.router.navigate(['/login']);
    }

    isLoggedIn(): boolean {
        return this.storage.getItem('credentials') !== null;
    }

    getHeaders(): HttpHeaders {
        const credentials = this.storage.getItem('credentials') as Credentials;

        return credentials
            ? new HttpHeaders({
                'Authorization': `${credentials.access_token}`,
                'Content-Type': 'application/json'
            }) : null;
    }

}
