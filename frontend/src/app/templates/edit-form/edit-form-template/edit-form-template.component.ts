import { Component, ViewChild, ViewContainerRef, OnInit, ComponentFactoryResolver, ComponentRef } from '@angular/core';
import { EditFormCommunicatorService } from '../edit-form-communicator.service';

@Component({
    selector: 'app-edit-form-template',
    templateUrl: './edit-form-template.component.html',
    styleUrls: ['./edit-form-template.component.css']
})
export class EditFormTemplateComponent implements OnInit {

    @ViewChild('editForm', { read: ViewContainerRef, static: true }) editFormRef: ViewContainerRef;

    constructor(
        private factoryResolver: ComponentFactoryResolver,
        private editFormCommunicatorService: EditFormCommunicatorService
    ) { }

    ngOnInit() {
        this.editFormCommunicatorService.getSubscription().subscribe(form => {
            if (form !== null) { this.loadForm(form); }
        });

    }

    loadForm(form) {
        const factory = this.factoryResolver.resolveComponentFactory(form);
        this.editFormRef.clear();
        this.editFormRef.createComponent(factory);
    }

    close() {
        this.editFormCommunicatorService.closeForm();
    }

}
