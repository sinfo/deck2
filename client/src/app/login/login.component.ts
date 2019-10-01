import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';

import { Credentials } from '../models/credentials';
import { AuthService } from '../deck-api/auth.service';
import { ThemeService } from '../theme.service';

@Component({
    selector: 'app-login',
    templateUrl: './login.component.html',
    styleUrls: ['./login.component.css']
})
export class LoginComponent implements OnInit {

    constructor(
        private auth: AuthService,
        private route: ActivatedRoute,
        private router: Router,
        private themeService: ThemeService
    ) {
    }

    ngOnInit() {

        if (this.auth.isLoggedIn()) {
            this.router.navigate(['']);
        }

        const token = this.route.snapshot.paramMap.get('token');

        if (token !== null) {
            const credentials = new Credentials();
            credentials.access_token = token;
            this.auth.saveCredentials(credentials);
            this.router.navigate(['']);
        }
    }

    login() {
        this.auth.login();
    }

}
