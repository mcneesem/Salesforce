import { LightningElement, api } from 'lwc';

export default class SandboxHealthLineItem extends LightningElement {
    @api label;
    @api actual;
    @api expected;
    @api message;
    @api isPass;
    @api isFail;
    @api isWarn;
}