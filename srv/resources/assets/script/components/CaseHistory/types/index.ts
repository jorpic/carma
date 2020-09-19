interface Item {
  caseId: number
  type: string
  datetime: string
}

interface HasUser {
  userid: number
}

interface ActionTask {
  isChecked: boolean
  id: number
  label: string
}

interface Location {
  latitude?: number,
  longitude?: number,
  description?: string
}

interface RequestBody {
  fullName?: string
  requestId?: string
  location?: Location
}

interface Vehicle {
  vin?: string
  plateNumber?: string
}

export interface Action extends Item, HasUser {
  type: 'action'
  actiontype: string
  actionresult?: string
  actioncomment?: string
  serviceid?: number
  servicelabel?: string
  tasks?: ActionTask[]
}

export interface Call extends Item, HasUser {
  type: 'call'
  calltype?: string
}

export interface Comment extends Item, HasUser {
  type: 'comment'
  commenttext?: string
}

export interface PartnerCancel extends Item, HasUser {
  type: 'partnerCancel'
  partnername?: string
  refusalcomment?: string
  refusalreason?: string
}

export interface PartnerDelay extends Item, HasUser {
  type: 'partnerDelay'
  partnername?: string
  delayminutes?: string
  delayconfirmed?: string
}

export interface SmsForPartner extends Item, HasUser {
  type: 'smsForPartner'
  deliverystatus?: string
  msgtext?: string
  phone?: string
  mtime?: string
}

export interface LocationSharingResponse extends Item, HasUser {
  type: 'locationSharingResponse'
  lat?: number
  lon?: number
}

export interface LocationSharingRequest extends Item, HasUser {
  type: 'locationSharingRequest'
  smsSent?: boolean
}

export interface CustomerFeedback extends Item, HasUser {
  type: 'customerFeedback'
  sender?: string
  accuracy?: number
  commenttext: string
  task?: ActionTask
}


export interface EraGlonassIncomingCallCard extends Item, HasUser {
  type: 'eraGlonassIncomingCallCard'
  id?: string
  requestBody?: RequestBody
  statusTime?: string,
  statusCode?: string
  serviceCategoryId?: string
  fccComment?: string,
  deferTime?: string,
  phoneNumber?: string,
  vehicle?: Vehicle,
  ivsPhoneNumber?: null,
}

type Timestamp = string
type UserName = string
type ItemData =
    Action
  | Call
  | Comment
  | PartnerCancel
  | PartnerDelay
  | SmsForPartner
  | LocationSharingResponse
  | LocationSharingRequest
  | CustomerFeedback
  | EraGlonassIncomingCallCard
export type HistoryItem = [Timestamp, UserName, ItemData]
