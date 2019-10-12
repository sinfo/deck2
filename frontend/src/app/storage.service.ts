import { Injectable } from '@angular/core';

@Injectable()
export class StorageService {

    private STORAGE_NAME = 'deck2';
    private internalStorage = {};

    constructor() {
    }

    setItem(key: string, value: object): void {
        try {
            localStorage.setItem(`${this.STORAGE_NAME}_${key}`, JSON.stringify(value));
        } catch (err) {
            this.internalStorage[key] = value;
        }
    }

    getItem(key: string): object {
        try {
            if (localStorage.getItem(`${this.STORAGE_NAME}_${key}`) === null) {
                this.removeItem(key);
                return null;
            }
            return JSON.parse(localStorage.getItem(`${this.STORAGE_NAME}_${key}`));
        } catch (err) {
            return this.internalStorage[key];
        }
    }

    removeItem(key: string): void {
        try {
            localStorage.removeItem(`${this.STORAGE_NAME}_${key}`);
            delete this.internalStorage[key];
        } catch (err) {
            console.error(err);
        }
    }

    clear(): void {
        try {
            localStorage.clear();
            this.internalStorage = {};
        } catch (err) {
            console.error(err);
        }
    }
}
