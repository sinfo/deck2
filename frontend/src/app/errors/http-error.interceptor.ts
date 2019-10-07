import { Injectable } from '@angular/core';

import { Router } from '@angular/router';

import { HttpEvent, HttpInterceptor, HttpHandler, HttpRequest, HttpErrorResponse } from '@angular/common/http';

import { Observable, throwError } from 'rxjs';
import { retry, catchError } from 'rxjs/operators';

import { AuthService } from '../deck-api/auth.service';

@Injectable({
    providedIn: 'root'
})
export class HttpErrorInterceptor implements HttpInterceptor {

    constructor(
        private auth: AuthService,
        private router: Router
    ) { }

    intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
        return next.handle(request)
            .pipe(
                catchError((error: HttpErrorResponse) => {
                    let errorMessage = '';

                    if (error.error instanceof ErrorEvent) {

                        // client-side error
                        errorMessage = `Client error: ${error.error.message}`;
                        window.alert(errorMessage);

                    } else {

                        // server-side error
                        switch (error.status) {
                            case 0:
                                if (this.router.url !== '/down') {
                                    this.router.navigate(['/down']);
                                }
                                return throwError('Server down or unreachable');
                            case 400:
                                errorMessage = `Error: ${error.error}`;
                                break;
                            case 401:
                                this.auth.logout();
                                return;
                            case 403:
                                errorMessage = 'Error: not enough credentials';
                                break;
                            default:
                                errorMessage = `Unknown error\n${error.message}\n${error.error}`;
                        }

                    }

                    window.alert(errorMessage);
                    return throwError(errorMessage);
                })
            );
    }
}
