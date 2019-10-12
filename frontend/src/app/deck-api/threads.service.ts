import { Injectable } from '@angular/core';

import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs/internal/Observable';

import { environment } from 'environments/environment';

import { Thread, AddCommentToThreadForm } from '../models/thread';

import { AuthService } from './auth.service';

@Injectable({
  providedIn: 'root'
})
export class ThreadsService {

  private headers: HttpHeaders;
  private url: String = `${environment.deck2}/threads`;

  constructor(
    private http: HttpClient,
    private auth: AuthService
  ) {
    this.headers = this.auth.getHeaders();
  }

  getThread(threadID: String): Observable<Thread> {
    return this.http.get<Thread>(`${this.url}/${threadID}`, { headers: this.headers });
  }

  addCommentToThread(comment: AddCommentToThreadForm): Observable<Thread> {
    return this.http.post<Thread>(`${this.url}/${comment.threadID}/comments`, comment.value(), { headers: this.headers });
  }

}
