import {h, FunctionalComponent} from 'preact'
import {Comment} from '../../../types'

type F<T> = FunctionalComponent<T>

type Props = {
  action: Comment
}

export const CaseComment: F<Props> = ({action: {commenttext}}) => {
  return <div class='comment'><b>Комментарий: </b>{commenttext}</div>
}
