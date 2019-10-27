import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { HTTP_INTERCEPTORS, HttpClientModule } from '@angular/common/http';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';

import { AppRoutes } from './app.routes';
import { HttpErrorInterceptor } from './errors/http-error.interceptor';
import { NgbAlertModule, NgbDropdownModule, NgbPopoverModule, NgbTabsetModule, NgbTypeaheadModule } from '@ng-bootstrap/ng-bootstrap';
import { intersectionObserverPreset, LazyLoadImageModule } from 'ng-lazyload-image'; // <-- include intersectionObserverPreset
import { AppComponent } from './app.component';
import { LoginComponent } from './login/login.component';
import { HomeComponent } from './home/home.component';
import { ServerDownComponent } from './errors/server-down/server-down.component';
import { MenuComponent } from './home/menu/menu.component';
import { ContentComponent } from './home/content/content.component';
import { CompaniesComponent } from './home/content/companies/companies.component';
import { SpeakersComponent } from './home/content/speakers/speakers.component';
import { SpeakerComponent } from './home/content/speaker/speaker.component';
import { FilterComponent } from './home/content/filter/filter.component';
import { TemplateSpeakers27Component } from './templates/speakers/template-speakers27/template-speakers27.component';
import { EditSpeakerFormComponent } from './templates/edit-form/edit-speaker-form/edit-speaker-form.component';
import { EditFormTemplateComponent } from './templates/edit-form/edit-form-template/edit-form-template.component';
import { DropdownComponent } from './templates/dropdown/dropdown.component';
import { PhotoComponent } from './templates/photo/photo.component';
import { ThreadComponent } from './home/content/thread/thread.component';
import { NotificationsComponent } from './home/menu/notifications/notifications.component';
import { ContactComponent } from './home/content/contact/contact.component';
import { TeamsComponent } from './home/content/teams/teams.component';
import { AddSpeakerFormComponent } from './templates/edit-form/add-speaker-form/add-speaker-form.component';
import { ItemsComponent } from './home/content/items/items.component';
import { AddItemFormComponent } from './templates/edit-form/add-item-form/add-item-form.component';
import { AddTeamFormComponent } from './templates/edit-form/add-team-form/add-team-form.component';
import { AddMemberToTeamFormComponent } from './templates/edit-form/add-member-to-team-form/add-member-to-team-form.component';
import { SessionsComponent } from './home/content/sessions/sessions.component';
import { AddCompanyFormComponent } from './templates/edit-form/add-company-form/add-company-form.component';
import { EditTeamMemberComponent } from './templates/edit-team-member/edit-team-member.component';

import { ParseStatusPipe } from './helpers/parse-status.pipe';
import { MarkdownPipe } from './helpers/markdown.pipe';
import { HighlightTagsPipe } from './helpers/highlight-tags.pipe';

import { SquareImageDirective } from './square-image.directive';

import { AuthService } from './deck-api/auth.service';
import { StorageService } from './storage.service';
import { MeService } from './deck-api/me.service';
import { EventsService } from './deck-api/events.service';
import { HealthService } from './deck-api/health.service';
import { CompaniesService } from './deck-api/companies.service';
import { SpeakersService } from './deck-api/speakers.service';
import { MembersService } from './deck-api/members.service';
import { FilterService } from './home/content/filter/filter.service';
import { ThemeService } from './theme.service';
import { ThreadsService } from './deck-api/threads.service';
import { PostsService } from './deck-api/posts.service';
import { EditFormService } from './templates/edit-form/edit-form.service';
import { ContactsService } from './deck-api/contacts.service';

@NgModule({
    declarations: [
        AppComponent,
        LoginComponent,
        HomeComponent,
        ServerDownComponent,
        MenuComponent,
        ContentComponent,
        CompaniesComponent,
        SpeakersComponent,
        SpeakerComponent,
        FilterComponent,
        TemplateSpeakers27Component,
        SquareImageDirective,
        EditSpeakerFormComponent,
        EditFormTemplateComponent,
        DropdownComponent,
        ParseStatusPipe,
        PhotoComponent,
        ThreadComponent,
        MarkdownPipe,
        HighlightTagsPipe,
        NotificationsComponent,
        ContactComponent,
        TeamsComponent,
        AddSpeakerFormComponent,
        AddCompanyFormComponent,
        ItemsComponent,
        AddItemFormComponent,
        AddTeamFormComponent,
        AddMemberToTeamFormComponent,
        SessionsComponent,
        EditTeamMemberComponent,
    ],
    imports: [
        BrowserModule,
        HttpClientModule,
        FormsModule,
        ReactiveFormsModule,
        AppRoutes,
        LazyLoadImageModule.forRoot({
            preset: intersectionObserverPreset
        }),
        NgbPopoverModule, NgbAlertModule, NgbDropdownModule,
        NgbTypeaheadModule, NgbTabsetModule
    ],
    providers: [
        AuthService,
        StorageService,
        {
            provide: HTTP_INTERCEPTORS,
            useClass: HttpErrorInterceptor,
            multi: true
        },
        MeService,
        EventsService,
        HealthService,
        CompaniesService,
        SpeakersService,
        MembersService,
        FilterService,
        ThemeService,
        ThreadsService,
        PostsService,
        EditFormService,
        ContactsService
    ],
    bootstrap: [AppComponent],
    entryComponents: [
        EditFormTemplateComponent, EditSpeakerFormComponent, AddSpeakerFormComponent,
        AddItemFormComponent, AddTeamFormComponent, AddMemberToTeamFormComponent,
        AddCompanyFormComponent, EditTeamMemberComponent
    ]
})
export class AppModule {
}
