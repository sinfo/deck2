import { FormControl, FormGroup, Validators } from '@angular/forms';
import { ItemsService } from '../deck-api/items.service';

export class Item {
    id: String;
    name: String;
    type: String;
    description: String;
    img: String;
    price: Number;
    vat: Number;
}

export class AddItemForm {

    form: FormGroup;

    constructor() {
        this.form = new FormGroup({
            name: new FormControl('', [Validators.required, Validators.minLength(1)]),
            type: new FormControl('', [Validators.required, Validators.minLength(1)]),
            price: new FormControl(0, [Validators.required, Validators.min(0)]),
            vat: new FormControl(0, [Validators.required, Validators.min(0), Validators.max(100)]),
            description: new FormControl('', [Validators.required]),
        });
    }

    value() {
        const value = this.form.value;
        value['price'] = Math.trunc(value['price'] * 100);
        return value;
    }

    valid() {
        return this.form.valid;
    }
}
