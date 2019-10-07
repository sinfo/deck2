import { ModuleWithProviders } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';

import { MemberGuard } from './auth/member.guard';

import { LoginComponent } from './login/login.component';
import { HomeComponent } from './home/home.component';
import { ServerDownComponent } from './errors/server-down/server-down.component';
import { CompaniesComponent } from './home/content/companies/companies.component';
import { SpeakersComponent } from './home/content/speakers/speakers.component';
import { SpeakerComponent } from './home/content/speaker/speaker.component';
import { TeamsComponent } from './home/content/teams/teams.component';
import { ItemsComponent } from './home/content/items/items.component';

import { TemplateSpeakers27Component } from './templates/speakers/template-speakers27/template-speakers27.component';

const appRoutes: Routes = [
    {
        path: 'login',
        component: LoginComponent,
    },
    {
        path: 'login/:token',
        component: LoginComponent,
    },
    {
        path: 'down',
        component: ServerDownComponent,
    },
    {
        path: 'templates',
        canActivate: [MemberGuard],
        children: [
            {
                path: 'events/27/speakers/:speakerID/posts/:postID',
                component: TemplateSpeakers27Component
            }
        ]
    },
    {
        path: '',
        component: HomeComponent,
        canActivate: [MemberGuard],
        children: [
            {
                path: 'companies',
                component: CompaniesComponent
            },
            {
                path: 'speakers',
                component: SpeakersComponent,
                pathMatch: 'full'
            },
            {
                path: 'speakers/:id',
                component: SpeakerComponent
            },
            {
                path: 'teams',
                component: TeamsComponent,
                pathMatch: 'full'
            },
            {
                path: 'items',
                component: ItemsComponent,
                pathMatch: 'full'
            },
        ]
    },
    {
        path: '**',
        redirectTo: ''
    }
];

export const AppRoutes: ModuleWithProviders = RouterModule.forRoot(appRoutes);
