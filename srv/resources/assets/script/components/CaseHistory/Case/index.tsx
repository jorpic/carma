import {h, FunctionalComponent, Fragment} from 'preact'
import {useMemo} from 'preact/hooks'
import moment from 'moment'
import {
  Action,
  Call,
  Comment,
  HistoryItem,
  LocationSharingRequest,
  LocationSharingResponse,
  PartnerCancel,
  PartnerDelay,
  SmsForPartner,
  EraGlonassIncomingCallCard, CustomerFeedback, Who
} from '../../types'

type F<T> = FunctionalComponent<T>

type Props = {
  caseData: HistoryItem
}

export const Case: F<Props> = ({caseData}) => {

  const [date, name, data] = caseData

  const sortByTypeData = useMemo(() => {

    switch (data.type) {

      case 'who': {
        return <CaseWho action={data}/>
      }

      case 'action': {
        return <CaseAction action={data}/>
      }

      case 'comment': {
        return <CaseComment action={data}/>
      }

      case 'partnerDelay': {
        return <CasePartnerDelay action={data}/>
      }

      case 'partnerCancel': {
        return <CasePartnerCancel action={data}/>
      }

      case 'call': {
        return <CaseCall action={data}/>
      }

      case 'smsForPartner': {
        return <CaseSmsForPartner action={data}/>
      }

      case 'locationSharingResponse': {
        return <CaseLocationSharingResponse action={data}/>
      }

      case 'locationSharingRequest': {
        return <CaseLocationSharingRequest action={data}/>
      }

      case 'customerFeedback': {
        return <CaseCustomerFeedback action={data}/>
      }

      case 'eraGlonassIncomingCallCard': {
        return <CaseEraGlonassIncomingCallCard action={data}/>
      }

      default:
        return <div>Что етто за тип?</div>
    }
  }, [caseData])

  return (
    <div class='history-body'>
      <div
        style='float: left'>{moment.utc(date).local().format('DD.MM.YYYY HH:mm:ss')}</div>
      <div style='float: right'>{name}</div>
      &nbsp;
      {sortByTypeData}
    </div>
  )
}

//CaseItem
type PropsItem = {
  name: string
  value?: string
  icon?: string
}

const CaseItem: F<PropsItem> = ({name, value, icon, children}) => {
  return (
    <div>
      {icon && <i class={`glyphicon glyphicon-${icon}`}/>}&nbsp;
      <b>{name}&nbsp;</b>
      {/*for type === eraGlonassIncomingCallCard*/}
      {children}
      {/**/}
      {value}
    </div>
  )
}
//CaseWho
type PropsWho = {
  action: Who
}

const CaseWho: F<PropsWho> = ({action: {who}}) => {
  return (
    <div class='history-who'>
      <span>{who}</span>
    </div>
  )
}
//CaseAction
type PropsAction = {
  action: Action
}

const CaseAction: F<PropsAction> = ({action: {actioncomment, actionresult, actiontype, servicelabel, tasks}}) => {
  return (
    <div class='action'>
      <CaseItem name='Действие:' value={actiontype} icon='briefcase'/>
      <CaseItem name='Результат:' value={actionresult}/>
      {servicelabel && <CaseItem name='Услуга:' value={servicelabel}/>}
      {tasks &&
      <div>
        <b>Задачи:&nbsp;</b>
        {tasks.map(({isChecked, label}) =>
          <Fragment>
            <input type='checkbox' disabled={isChecked}/>
            {label}
          </Fragment>
        )}
      </div>
      }
      {actioncomment && <CaseItem name='Комментарий:' value={actioncomment}/>}
    </div>
  )
}

//CaseCall
type PropsCall = {
  action: Call
}

const CaseCall: F<PropsCall> = ({action: {calltype}}) => <CaseItem name='Звонок:' value={calltype} icon='phone-alt'/>

//CaseComment
type PropsComment = {
  action: Comment
}

const CaseComment: F<PropsComment> = ({action: {commenttext}}) => <CaseItem name='Комментарий:' value={commenttext}/>

//CaseCustomerFeedback
type PropsCustomerFeedback = {
  action: CustomerFeedback
}

const CaseCustomerFeedback: F<PropsCustomerFeedback> = ({action: {task, commenttext}}) => {
  return (
    <Fragment>
      <CaseItem name='Отзыв клиента:' value={task.label} icon='star'/>
      <CaseItem name='Комментарий:' value={commenttext}/>
    </Fragment>
  )
}

//CaseLocationSharingRequest
type PropsLocationSharingRequest = {
  action: LocationSharingRequest
}

const CaseLocationSharingRequest: F<PropsLocationSharingRequest> = () =>
  <CaseItem name='Клиенту отправлено SMS с запросом местоположения:' icon='map-marker'/>

//CaseLocationSharingResponse
type PropsLocationSharingResponse = {
  action: LocationSharingResponse
}

const CaseLocationSharingResponse: F<PropsLocationSharingResponse> = ({action: {lat, lon,}}) => {
  const lonlat = `${lon.toPrecision(7)},${lat.toPrecision(7)}`
  const mapUrl = `https://maps.yandex.ru/?z=18&l=map&pt=${lonlat}`
  return (
    <div>
      <CaseItem name='От клиента пришёл ответ с координатами:'
                icon='map-marker'/>
      <a href={mapUrl} target='_blank'>{lonlat}</a>
      <div style='float: right'>
        <a href='#' onClick={null}>Скопировать в буфер обмена</a>
      </div>
      <div style='clear:both'/>
    </div>
  )
}
//CasePartnerCancel
type PropsPartnerCancel = {
  action: PartnerCancel
}

const CasePartnerCancel: F<PropsPartnerCancel> = ({action: {refusalreason, refusalcomment, partnername}}) => {
  return (
    <div>
      <CaseItem name='Отказ партнёра:' value={partnername} icon='time'/>

      <div>
        <CaseItem name='Причина отказа:' value={refusalreason}/>
        {refusalcomment && `\xa0${refusalcomment}`}
      </div>
    </div>
  )
}
//CasePartnerDelay
type PropsPartnerDelay = {
  action: PartnerDelay
}

const CasePartnerDelay: F<PropsPartnerDelay> = ({action: {delayconfirmed, delayminutes, partnername}}) => {
  return (
    <div>
      <CaseItem name='Опоздание партнёра:' value={partnername} icon='time'/>
      <CaseItem name='Время опоздания:' value={delayminutes}/>
      <CaseItem name='Опоздание согласовано:' value={delayconfirmed}/>
    </div>
  )
}
//CaseSmsForPartner
type PropsSmsForPartner = {
  action: SmsForPartner
}

const CaseSmsForPartner: F<PropsSmsForPartner> = ({action: {deliverystatus, msgtext, phone, mtime}}) => {
  return (
    <div>
      <CaseItem name='Партнёру отправлено SMS:' value={msgtext}
                icon='envelope'/>
      <CaseItem name='Телефон получателя:' value={phone}/>
      <CaseItem name='Статус отправки:' value={deliverystatus}/>
      <span>(обновлено: {mtime})</span>
    </div>
  )
}
//CaseEraGlonassIncomingCallCard
type PropsEraGlonassIncomingCallCard = {
  action: EraGlonassIncomingCallCard
}

const CaseItemItalic: F<PropsItem> = ({name, value}) => {
  return (
    <div>
      <i>{name}</i>&nbsp;
      <span>{value}</span>
    </div>
  )
}

const CaseEraGlonassIncomingCallCard: F<PropsEraGlonassIncomingCallCard> =
  ({action: {requestBody, ivsPhoneNumber, phoneNumber, vehicle}}) => {
    return (
      <div>
        <CaseItem name='Поступление заявки на обслуживание от ЭРА-ГЛОНАСС.'
                  icon='globe'/>
        <CaseItem name='Идентификатор заявки на обслуживание:'
                  value={requestBody.requestId}/>
        <CaseItem name='Имя звонящего:' value={requestBody?.fullName || '✗'}/>
        <CaseItem name='Номера телефонов:' icon='earphone'>
          <CaseItemItalic name='Терминала авто:' value={ivsPhoneNumber || '✗'}/>
          <CaseItemItalic name='Звонящий:' value={phoneNumber || '✗'}/>
        </CaseItem>
        <CaseItem name='Транспорт:'>
          <CaseItemItalic name='VIN:' value={vehicle?.vin || '✗'}/>
          <CaseItemItalic name='Регистрационный номер:'
                          value={vehicle?.plateNumber || '✗'}/>
        </CaseItem>
        <CaseItem name='Описание местонахождения:'
                  value={requestBody?.location?.description || '✗'}/>
        <CaseItem name='Координаты:' icon='screenshot'>

          <CaseItemItalic name='Широта'
                          value={(requestBody?.location?.latitude / (3600 * 1000)).toLocaleString('ru-RU', {
                            minimumFractionDigits: 6,
                            maximumFractionDigits: 6,
                          }) + '°'}/>

          <CaseItemItalic name='Долгота'
                          value={(requestBody?.location?.longitude / (3600 * 1000)).toLocaleString('ru-RU', {
                            minimumFractionDigits: 6,
                            maximumFractionDigits: 6,
                          }) + '°'}/>
        </CaseItem>
      </div>
    )
  }
