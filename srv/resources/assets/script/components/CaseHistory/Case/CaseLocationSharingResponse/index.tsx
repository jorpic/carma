import {h, FunctionalComponent} from 'preact'
import {LocationSharingResponse} from '../../../types'

type F<T> = FunctionalComponent<T>

type Props = {
  action: LocationSharingResponse
}

export const CaseLocationSharingResponse: F<Props> = ({action: {lat, lon,}}) => {
  const lonlat = `${lon.toPrecision(7)},${lat.toPrecision(7)}`
  const mapUrl = `https://maps.yandex.ru/?z=18&l=map&pt=${lonlat}`
  return (
    <div>
      <i class='glyphicon glyphicon-map-marker'/>
      <b>От клиента пришёл ответ с координатами:{`\xa0`}</b>
      <a href={mapUrl} target='_blank'>{lonlat}</a>
      <div style='float: right'>
        <a href='#' onClick={null}>Скопировать в буфер обмена</a>
      </div>
      <div style='clear:both'/>
    </div>
  )
}
