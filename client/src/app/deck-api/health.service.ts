import { Injectable, OnDestroy } from '@angular/core';

import { Router } from '@angular/router';

import { HttpClient } from '@angular/common/http';

import { interval, of } from 'rxjs';
import { map, catchError } from 'rxjs/operators';

import { Subscription } from 'rxjs/internal/Subscription';
import { Observable } from 'rxjs/internal/Observable';

import { environment } from 'environments/environment';

@Injectable({
  providedIn: 'root'
})
export class HealthService implements OnDestroy {

  private healthRequestPeriod = interval(5 * 1000); // 10 seconds
  private healthSubscription: Subscription;

  private url: String = `${environment.deck2}/health`;

  constructor(
    private http: HttpClient,
    private router: Router
  ) {}

  ngOnDestroy() {
    this.healthSubscription.unsubscribe();
  }

  subscribeHealthCheck() {
    this.healthSubscription = this.healthRequestPeriod.subscribe(() => {
      this.checkHealth().subscribe(
        ok => { if (ok) { this.router.navigate(['/']); this.ngOnDestroy(); } }
      );
    });
  }

  checkHealth(): Observable<boolean> {

    return this.http.get(`${this.url}`, { responseType: 'text' })
    .pipe(
      map(_ => true),
      catchError((error, caught) => of(false))
    );

  }

}
