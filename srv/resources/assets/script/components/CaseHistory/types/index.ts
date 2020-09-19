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
  latitude: number,
  longitude: number,
  description: string | null
}

interface RequestBody {
  fullName: string | null
  ivsPhoneNumber: string | null
  phoneNumber: string | null
  vehicle: Vehicle | null
  location: Location | null
}

interface Vehicle {
  vin: string | null
  plateNumber: string | null
}

export interface Action extends Item, HasUser {
  type: 'action'
  actiontype: string
  actionresult: string
  actioncomment: string
  serviceid?: number
  servicelabel?: string
  tasks?: ActionTask[]
}

export interface Call extends Item, HasUser {
  type: 'call'
  calltype: string
}

export interface Comment extends Item, HasUser {
  type: 'comment'
  commenttext: string
}

export interface PartnerCancel extends Item, HasUser {
  type: 'partnerCancel'
  partnername: string
  refusalcomment: string
  refusalreason: string
}

export interface PartnerDelay extends Item, HasUser {
  type: 'partnerDelay'
  serviceid: number
  servicelabel: string
  partnername: string
  delayminutes: string
  delayconfirmed: string
}

export interface SmsForPartner extends Item, HasUser {
  type: 'smsForPartner'
  deliverystatus: string
  msgtext: string
  phone: string
  mtime: string | null
}

export interface LocationSharingResponse extends Item, HasUser {
  type: 'locationSharingResponse'
  lat: number
  lon: number
  accuracy: number
}

export interface LocationSharingRequest extends Item, HasUser {
  type: 'locationSharingRequest'
  smsSent: boolean
}

export interface CustomerFeedback extends Item, HasUser {
  type: 'customerFeedback'
  value: number
  label: string
  comment: string
}

export interface EraGlonassIncomingCallCard extends Item, HasUser {
  type: 'eraGlonassIncomingCallCard'
  requestId: number
  requestBody: RequestBody
}

export interface AvayaEvent extends Item, HasUser {
  type: 'avayaEvent'
  aetype: string
  aeinterlocutors: string
  aecall: number
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
