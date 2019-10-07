import { Injectable, OnDestroy } from '@angular/core';

import { HttpClient, HttpHeaders } from '@angular/common/http';

import { interval } from 'rxjs';
import { Subscription } from 'rxjs/internal/Subscription';
import { Observable } from 'rxjs/internal/Observable';
import { ReplaySubject } from 'rxjs/internal/ReplaySubject';
import 'rxjs/add/operator/mergeMap';

import { environment } from 'environments/environment';
import { Member } from '../models/member';

import { Role } from "../models/role";
import { Notification, NotificationArraysEqual } from '../models/notification';
import { AuthService } from './auth.service';
import { MembersService } from "./members.service";

@Injectable({
    providedIn: 'root'
})
export class MeService implements OnDestroy {

    private notificationsSubject: ReplaySubject<Notification[]> = new ReplaySubject<Notification[]>();
    private notificationRequestPeriod = interval(10 * 1000); // 10 seconds
    private notificationSubscription: Subscription;

    private notifications: Notification[] = [] as Notification[];

    private url: String = `${environment.deck2}/me`;
    private headers: HttpHeaders;

    constructor(
        private http: HttpClient,
        private auth: AuthService,
        private membersService: MembersService
    ) {
        this.headers = this.auth.getHeaders();

        this.refreshNotifications();
        this.notificationSubscription = this.notificationRequestPeriod.subscribe(() => {
            this.refreshNotifications();
        });
    }

    ngOnDestroy() {
        this.notificationSubscription.unsubscribe();
    }

    getMe(): Observable<Member> {
        return this.http.get<Member>(`${this.url}`, { headers: this.headers });
    }

    subscribeToNotifications(context): [Notification[], Subscription] {
        return [
            this.notifications,
            this.notificationsSubject.asObservable().subscribe((notifications: Notification[]) => {
                context.notifications = notifications;
            })
        ];
    }

    removeNotification(id: String): Observable<void> {
        return this.http.delete<void>(`${this.url}/notifications/${id}`, { headers: this.headers });
    }

    getMyRole(): Observable<Role> {
        return this.getMe().mergeMap((me: Member) => {
            return this.membersService.getRole(me.id);
        });
    }

    refreshNotifications() {
        return this.http.get<Notification[]>(`${this.url}/notifications`, { headers: this.headers })
            .subscribe((notifications: Notification[]) => {

                // only emit the notifications if they differ from the stored ones
                const emit = !NotificationArraysEqual(this.notifications, notifications);
                if (!emit) {
                    return;
                }
                this.notifications = notifications;
                this.notificationsSubject.next(notifications);
            }
            );
    }

}
