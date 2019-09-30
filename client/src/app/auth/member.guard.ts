import { Injectable } from '@angular/core';
import { CanActivate, ActivatedRouteSnapshot, RouterStateSnapshot, Router } from '@angular/router';
import { AuthService } from '../deck-api/auth.service';

@Injectable({
  providedIn: 'root'
})
export class MemberGuard implements CanActivate {

  constructor(
    private auth: AuthService,
    private router: Router
  ) { }

  canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): boolean {
    const isAuthenticated = this.auth.isLoggedIn();

    if (!isAuthenticated) {
      this.router.navigate(['login']);
    }

    return isAuthenticated;
  }

}
