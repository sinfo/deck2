import {HttpClient, HttpHeaders, HttpParams} from '@angular/common/http';
import {Injectable} from '@angular/core';
import {environment} from 'environments/environment';
import {Observable} from 'rxjs/internal/Observable';

import {Session} from '../models/session';

import {AuthService} from './auth.service';

@Injectable({providedIn: 'root'})
export class PostsService {
  private headers: HttpHeaders;
  private url: String = `${environment.deck2}/posts`;

  constructor(private http: HttpClient, private auth: AuthService) {
    this.headers = this.auth.getHeaders();
  }
}
