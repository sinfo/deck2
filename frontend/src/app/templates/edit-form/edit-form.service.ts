import { ComponentFactoryResolver, Injectable, ViewContainerRef } from '@angular/core';

import { EditFormCommunicatorService, AppliedFormCallback } from './edit-form-communicator.service';

import { EditSpeakerFormComponent } from './edit-speaker-form/edit-speaker-form.component';
import { AddSpeakerFormComponent } from './add-speaker-form/add-speaker-form.component';
import { EditFormTemplateComponent } from './edit-form-template/edit-form-template.component';
import { AddItemFormComponent } from './add-item-form/add-item-form.component';
import { AddMemberToTeamFormComponent } from './add-member-to-team-form/add-member-to-team-form.component';
import { AddTeamFormComponent } from './add-team-form/add-team-form.component';
import { AddCompanyFormComponent } from './add-company-form/add-company-form.component';

import { Speaker } from '../../models/speaker';
import { PopulatedTeam } from '../../models/team';

@Injectable({
    providedIn: 'root'
})
export class EditFormService {

    private viewContainerRef: ViewContainerRef;

    constructor(
        private factoryResolver: ComponentFactoryResolver,
        private editFormCommunicatorService: EditFormCommunicatorService
    ) {
        this.editFormCommunicatorService.getSubscription().subscribe(form => {
            if (form === null) { this.closeForm(); }
        });
    }

    showSpeakerEditForm(viewContainerRef: ViewContainerRef, speaker: Speaker, callback?: AppliedFormCallback) {
        this.viewContainerRef = viewContainerRef;
        const factory = this.factoryResolver.resolveComponentFactory(EditFormTemplateComponent);
        viewContainerRef.createComponent(factory);

        this.editFormCommunicatorService.setForm(EditSpeakerFormComponent);
        this.editFormCommunicatorService.data = speaker;

        if (callback) {
            this.editFormCommunicatorService.subscribeCallback(callback);
        }
    }

    showAddSpeakerForm(viewContainerRef: ViewContainerRef, callback?: AppliedFormCallback) {
        this.viewContainerRef = viewContainerRef;
        const factory = this.factoryResolver.resolveComponentFactory(EditFormTemplateComponent);
        viewContainerRef.createComponent(factory);

        this.editFormCommunicatorService.setForm(AddSpeakerFormComponent);

        if (callback) {
            this.editFormCommunicatorService.subscribeCallback(callback);
        }
    }

    showAddCompanyForm(viewContainerRef: ViewContainerRef, callback?: AppliedFormCallback) {
        this.viewContainerRef = viewContainerRef;
        const factory = this.factoryResolver.resolveComponentFactory(EditFormTemplateComponent);
        viewContainerRef.createComponent(factory);

        this.editFormCommunicatorService.setForm(AddCompanyFormComponent);

        if (callback) {
            this.editFormCommunicatorService.subscribeCallback(callback);
        }
    }

    showAddItemForm(viewContainerRef: ViewContainerRef, callback?: AppliedFormCallback) {
        this.viewContainerRef = viewContainerRef;
        const factory = this.factoryResolver.resolveComponentFactory(EditFormTemplateComponent);
        viewContainerRef.createComponent(factory);

        this.editFormCommunicatorService.setForm(AddItemFormComponent);

        if (callback) {
            this.editFormCommunicatorService.subscribeCallback(callback);
        }
    }

    showAddTeamForm(viewContainerRef: ViewContainerRef, callback?: AppliedFormCallback) {
        this.viewContainerRef = viewContainerRef;
        const factory = this.factoryResolver.resolveComponentFactory(EditFormTemplateComponent);
        viewContainerRef.createComponent(factory);

        this.editFormCommunicatorService.setForm(AddTeamFormComponent);

        if (callback) {
            this.editFormCommunicatorService.subscribeCallback(callback);
        }
    }

    showAddMemberToTeamForm(viewContainerRef: ViewContainerRef, team: PopulatedTeam, callback?: AppliedFormCallback) {
        this.viewContainerRef = viewContainerRef;
        const factory = this.factoryResolver.resolveComponentFactory(EditFormTemplateComponent);
        viewContainerRef.createComponent(factory);

        this.editFormCommunicatorService.setForm(AddMemberToTeamFormComponent);
        this.editFormCommunicatorService.data = team;

        if (callback) {
            this.editFormCommunicatorService.subscribeCallback(callback);
        }
    }

    closeForm() {
        this.viewContainerRef.clear();
    }

}
