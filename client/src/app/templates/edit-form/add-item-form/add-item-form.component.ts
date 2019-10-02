import { Component } from '@angular/core';

import { ItemsService } from '../../../deck-api/items.service';
import { EventsService } from '../../../deck-api/events.service';
import { EditFormCommunicatorService, AppliedForm } from '../edit-form-communicator.service';

import { AddItemForm, Item } from '../../../models/item';

@Component({
    selector: 'app-add-item-form',
    templateUrl: './add-item-form.component.html',
    styleUrls: ['./add-item-form.component.css']
})
export class AddItemFormComponent {

    form: AddItemForm;

    constructor(
        private editFormCommunicatorService: EditFormCommunicatorService,
        private itemsService: ItemsService,
        private eventsService: EventsService
    ) {
        this.form = new AddItemForm();
    }

    submitNewItem() {
        if (!this.form.valid()) { return; }

        this.itemsService.createItem(this.form).subscribe((item: Item) => {
            this.eventsService.addItem(`${item.id}`).subscribe(() => {
                this.editFormCommunicatorService.setAppliedForm(AppliedForm.AddItem);
                this.editFormCommunicatorService.closeForm();
            });
        });
    }

}
