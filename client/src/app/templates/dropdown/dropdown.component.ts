import { Component, OnInit, ViewChildren, ViewContainerRef, Input, TemplateRef, AfterViewInit, QueryList } from '@angular/core';

@Component({
  selector: 'app-dropdown',
  templateUrl: './dropdown.component.html',
  styleUrls: ['./dropdown.component.css']
})
export class DropdownComponent implements OnInit, AfterViewInit {

  @ViewChildren('_labelTemplate', { read: ViewContainerRef }) _labelTemplate: QueryList<ViewContainerRef>;
  @ViewChildren('_optionsTemplate', { read: ViewContainerRef }) _optionsTemplate: QueryList<ViewContainerRef>;

  @Input() options: any[];
  @Input() labelTemplate: TemplateRef<any>;
  @Input() optionsTemplate: TemplateRef<any>;

  constructor() { }

  ngOnInit() {}

  ngAfterViewInit() {
    setTimeout(() => {
      this.update();
    });
  }

  update() {

    this._labelTemplate.forEach((templateRef) => {
      templateRef.createEmbeddedView(this.labelTemplate);
    });

    this._optionsTemplate.forEach((templateRef) => {
      templateRef.createEmbeddedView(this.optionsTemplate);
    });

  }

}
