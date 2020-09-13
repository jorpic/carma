import {h, FunctionalComponent} from 'preact'
import {LocationSharingRequest} from '../../../types'

type F<T> = FunctionalComponent<T>

type Props = {
  action: LocationSharingRequest
}

export const CaseLocationSharingRequest: F<Props> = () => {
  return (
    <div>
      <i class='glyphicon glyphicon-map-marker'/>
      <b>Клиенту отправлено SMS с запросом местоположения</b>
    </div>
  )
}
