import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createRegistration from '@salesforce/apex/SportsRegistrationController.createRegistration';

export default class SportsRegistrationForm extends LightningElement {
    @track isFormOpen = false;
    @track sport = '';
    @track teamName = '';
    @track players = 0;
    @track fee = 0;

    get toggleLabel() {
        return this.isFormOpen ? 'Close Form' : 'Open Form';
    }

    get sportOptions() {
        return [
            { label: 'Cricket', value: 'Cricket' },
            { label: 'Kabaddi', value: 'Kabaddi' },
            { label: 'Volley Ball', value: 'Volley Ball' },
            { label: 'Throw Ball', value: 'Throw Ball' },
            { label: 'Basket Ball', value: 'Basket Ball' },
            { label: 'Tennikoit', value: 'Tennikoit' },
            { label: 'Badminton', value: 'Badminton' },
            { label: 'Kho-Kho', value: 'Kho-Kho' },
            { label: 'Chess', value: 'Chess' },
            { label: 'Tug of War', value: 'Tug of War' },
            { label: 'Carroms', value: 'Carroms' },
            { label: 'Table-Tennis', value: 'Table-Tennis' },
            { label: 'Others', value: 'Others' }
        ];
    }

    toggleForm() {
        this.isFormOpen = !this.isFormOpen;
    }

    handleChange(event) {
        this[event.target.name] = event.target.value;
    }

    handleRegister() {
        createRegistration({
            sport: this.sport,
            teamName: this.teamName,
            players: this.players,
            fee: this.fee
        })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Team Registered Successfully!',
                        variant: 'success'
                    })
                );
                this.resetForm();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }

    resetForm() {
        this.sport = '';
        this.teamName = '';
        this.players = 0;
        this.fee = 0;
    }
}