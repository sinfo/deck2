import { Injectable } from '@angular/core';

import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs/internal/Observable';

import { environment } from 'environments/environment';

import { Post } from '../models/post';

import { AuthService } from './auth.service';

@Injectable({
  providedIn: 'root'
})
export class PostsService {

  private headers: HttpHeaders;
  private url: String = `${environment.deck2}/posts`;

  constructor(
    private http: HttpClient,
    private auth: AuthService
  ) {
    this.headers = this.auth.getHeaders();
  }

  getPost(postID: String): Observable<Post> {
    return this.http.get<Post>(`${this.url}/${postID}`, { headers: this.headers });
  }
}
